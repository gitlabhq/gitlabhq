# frozen_string_literal: true

module QA
  # rubocop:disable Fips/MD5 -- not applicable
  RSpec.describe Tools::Ci::PipelineCreator do
    include Support::Helpers::StubEnv

    subject(:pipeline_creator) do
      described_class.new(
        test_files,
        logger: instance_double(Logger, info: nil, debug: nil),
        pipeline_path: tmp_dir,
        env: env
      )
    end

    let(:test_files) { [] }
    let(:env) { {} }
    let(:tmp_dir) { Dir.mktmpdir }
    let(:project_root) { File.expand_path("../", Runtime::Path.qa_root) }
    let(:cng_pipeline_file) { File.join(tmp_dir, "test-on-cng-pipeline.yml") }
    let(:generated_cng_yaml) { YAML.load_file(cng_pipeline_file) }

    let(:skip_pipeline) { File.read(File.join(project_root, ".gitlab/ci/_skip.yml")) }
    let(:noop_reason) { "no-op run, nothing will be executed!" }
    let(:noop_pipeline) do
      <<~YML
        variables:
          SKIP_MESSAGE: "#{noop_reason}"

        #{skip_pipeline}
      YML
    end

    describe "#create_noop" do
      let(:scenario_examples) { {} }
      let(:noop_reason) { "no-op run, pipeline:skip-e2e label detected" }

      before do
        allow(File).to receive(:write).with(/test-on-(gdk|cng|omnibus|omnibus-nightly)-pipeline.yml/, noop_pipeline)
      end

      it "creates a noop pipeline with skip message" do
        described_class.create_noop(
          logger: instance_double(Logger, info: nil, debug: nil),
          pipeline_path: tmp_dir,
          reason: noop_reason
        )

        expect(File).to have_received(:write).with(cng_pipeline_file, noop_pipeline)
      end
    end

    describe "#create" do
      let(:scenario_class) do
        Class.new(Scenario::Template) do
          pipeline_mappings test_on_cng: ['cng-instance']
        end
      end

      let(:runtime) { 10 }
      let(:runtime_report) { { example => runtime } }
      let(:example) { "spec_file.rb[1:1]" }
      let(:status) { "passed" }
      let(:ruby_version) { "3.2.5" }
      let(:gitlab_version) { "18.0.0" }
      let(:md5_sum) { instance_double(Digest::MD5, hexdigest: "3596609a928fe9877e37ed6e9c4f87fa") }

      let(:scenario_examples) do
        {
          scenario_class => [{ id: example, status: status }],
          Class.new(Scenario::Template) => [{ id: "spec_file.rb[1:2]", status: "passed" }]
        }
      end

      let(:omnibus_pipeline_definition) { {} }
      let(:cng_pipeline_definition) do
        {
          "cng-instance" => {
            "stage" => "test",
            "script" => "echo 'test'"
          },
          "some-other-job" => {
            "stage" => "report"
          }
        }
      end

      let(:pipeline_definitions) do
        {
          "test-on-cng" => cng_pipeline_definition.to_yaml,
          "test-on-omnibus" => omnibus_pipeline_definition.to_yaml,
          "test-on-gdk" => "",
          "test-on-omnibus-nightly" => ""
        }
      end

      let(:variables) do
        {
          "GITLAB_SEMVER_VERSION" => gitlab_version,
          "GITLAB_QA_CACHE_KEY" => "qa-e2e-ruby-#{ruby_version}-#{md5_sum.hexdigest}",
          "FEATURE_FLAGS" => env["QA_FEATURE_FLAGS"],
          "QA_SUITES" => scenario_class.to_s
        }.compact
      end

      before do
        stub_env("RUBY_VERSION", ruby_version)
        stub_env("CI_PROJECT_NAMESPACE", "gitlab-org")

        allow(Tools::Ci::ScenarioExamples).to receive(:fetch).with(test_files).and_return(scenario_examples)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(File.join(project_root, "VERSION")).and_return(gitlab_version)

        pipeline_definitions.each do |pipeline_type, definition|
          allow(File).to receive(:read)
            .with(File.join(project_root, ".gitlab/ci/#{pipeline_type}/main.gitlab-ci.yml"))
            .and_return(definition)
        end

        allow(JSON).to receive(:load_file).with(Support::KnapsackReport::RUNTIME_REPORT).and_return(runtime_report)
        allow(Digest::MD5).to receive(:file).and_return(md5_sum)
      end

      context "with successful pipeline creation" do
        it "only creates pipeline definitions for pipeline mappings present in scenarios", :aggregate_failures do
          pipeline_creator.create

          (described_class::SUPPORTED_PIPELINES - [:test_on_cng]).each do |pipeline_type|
            expect(File.exist?(File.join(tmp_dir, "#{pipeline_type.to_s.tr('_', '-')}-pipeline.yml"))).to(
              be(false),
              "Expected pipeline file to not be created for #{pipeline_type}"
            )
          end
        end

        it "adds default variables section to created pipeline" do
          pipeline_creator.create

          expect(generated_cng_yaml).to include({ "variables" => variables })
        end

        it "does not mutate unmapped jobs" do
          pipeline_creator.create

          expect(generated_cng_yaml).to include("some-other-job" => cng_pipeline_definition["some-other-job"])
        end

        it "only creates specifically selected pipelines" do
          pipeline_creator.create([:test_on_omnibus])

          expect(File.exist?(cng_pipeline_file)).to be(false)
        end

        it "raises error on incorrect pipeline type in argument" do
          expect { pipeline_creator.create([:test_on_dot_com]) }.to raise_error(ArgumentError)
        end

        context "with specific test files" do
          let(:test_files) { ["some_spec.rb", "some_other_spec.rb"] }

          it "adds QA_TESTS variable to job definition" do
            pipeline_creator.create

            expect(generated_cng_yaml).to include({
              "variables" => variables.deep_merge({ "QA_TESTS" => test_files.join(" ") })
            })
          end
        end

        context "with skipped job" do
          let(:second_scenario_class) do
            Class.new(Scenario::Template) do
              pipeline_mappings test_on_cng: ['cng-second-job']
            end
          end

          let(:scenario_examples) do
            {
              scenario_class => [{ id: example, status: "pending" }],
              second_scenario_class => [{ id: example, status: "passed" }]
            }
          end

          context "with existing rule" do
            let(:cng_pipeline_definition) do
              {
                "cng-instance" => {
                  "stage" => "test",
                  "rules" => [{ "if" => "condition" }, { "when" => "always" }],
                  "script" => "echo 'test'"
                },
                "cng-second-job" => {
                  "stage" => "test",
                  "script" => "echo 'test'"
                }
              }
            end

            it "replaces existing rule with rule: never" do
              pipeline_creator.create

              expect(generated_cng_yaml).to include(cng_pipeline_definition.deep_merge({
                "cng-instance" => {
                  "rules" => [{ "when" => "never" }]
                },
                "cng-second-job" => {
                  "parallel" => 1
                }
              }))
            end
          end

          context "without existing rule" do
            let(:cng_pipeline_definition) do
              {
                "cng-instance" => {
                  "stage" => "test",
                  "script" => "echo 'test'"
                },
                "cng-second-job" => {
                  "stage" => "test",
                  "script" => "echo 'test'"
                }
              }
            end

            it "adds rule: never" do
              pipeline_creator.create

              expect(generated_cng_yaml).to include(cng_pipeline_definition.deep_merge({
                "cng-instance" => {
                  "rules" => [{ "when" => "never" }]
                },
                "cng-second-job" => {
                  "parallel" => 1
                }
              }))
            end
          end
        end

        context "with all jobs having 0 runtime" do
          let(:noop_reason) { "no-op run, pipeline has no executable tests" }
          let(:scenario_examples) { { scenario_class => [{ id: example, status: "pending" }] } }

          it "create noop pipeline" do
            pipeline_creator.create

            expect(generated_cng_yaml).to eq(YAML.safe_load(noop_pipeline))
          end
        end

        context "with multiple mapped jobs" do
          let(:second_scenario_class) do
            Class.new(Scenario::Template) do
              pipeline_mappings test_on_cng: ['cng-second-job']
            end
          end

          let(:scenario_examples) do
            {
              scenario_class => [{ id: example, status: status }],
              second_scenario_class => [{ id: example, status: "pending" }]
            }
          end

          let(:cng_pipeline_definition) do
            {
              "cng-instance" => {
                "stage" => "test",
                "script" => "echo 'test'"
              },
              "cng-second-job" => {
                "stage" => "test",
                "script" => "echo 'test'"
              },
              "some-other-job" => {
                "stage" => "report"
              }
            }
          end

          it "sets correct parallel job count and rules for jobs" do
            pipeline_creator.create

            expect(generated_cng_yaml).to include(cng_pipeline_definition.deep_merge({
              "cng-instance" => {
                "parallel" => 1
              },
              "cng-second-job" => {
                "rules" => [{ "when" => "never" }]
              }
            }))
          end
        end

        context "with pipeline type without custom coefficient" do
          let(:runtime) { (21 * 60).to_f }

          let(:omnibus_pipeline_definition) do
            {
              "instance" => {
                "stage" => "test",
                "script" => "echo 'test'"
              },
              "some-other-job" => {
                "stage" => "report"
              }
            }
          end

          let(:second_scenario_class) do
            Class.new(Scenario::Template) do
              pipeline_mappings test_on_omnibus: ['instance']
            end
          end

          let(:scenario_examples) do
            {
              scenario_class => [{ id: example, status: status }],
              second_scenario_class => [{ id: example, status: status }]
            }
          end

          let(:generated_omnibus_yaml) { YAML.load_file(File.join(tmp_dir, "test-on-omnibus-pipeline.yml")) }

          it "scales up jobs based on defined pipeline type coefficient" do
            pipeline_creator.create

            expect(generated_cng_yaml).to include(cng_pipeline_definition.deep_merge({
              "cng-instance" => {
                "parallel" => 1
              }
            }))
            expect(generated_omnibus_yaml).to include(omnibus_pipeline_definition.deep_merge({
              "instance" => {
                "parallel" => 2
              }
            }))
          end
        end

        context "when runtime is above threshold" do
          let(:runtime) { (60 * 60).to_f }

          it "scales up parallel job count" do
            pipeline_creator.create

            expect(generated_cng_yaml).to include(cng_pipeline_definition.deep_merge({
              "cng-instance" => {
                "parallel" => 3
              }
            }))
          end
        end

        context "without runtime data" do
          let(:runtime_report) { {} }

          it "uses default minimal runtime value" do
            pipeline_creator.create

            expect(generated_cng_yaml).to include(cng_pipeline_definition.deep_merge({
              "cng-instance" => {
                "parallel" => 1
              }
            }))
          end
        end

        context "with existing parallel job count" do
          let(:cng_pipeline_definition) do
            {
              "cng-instance" => {
                "stage" => "test",
                "parallel" => 24,
                "script" => "echo 'test'"
              },
              "some-other-job" => {
                "stage" => "report"
              }
            }
          end

          it "updates parallel count according to runtime data" do
            pipeline_creator.create

            expect(generated_cng_yaml).to include(cng_pipeline_definition.deep_merge({
              "cng-instance" => {
                "parallel" => 1
              }
            }))
          end
        end

        context "with additional env setup" do
          let(:env) do
            {
              "QA_FEATURE_FLAGS" => "foo,bar",
              "KNAPSACK_TEST_FILE_PATTERN" => "file_pattern"
            }
          end

          it "adds additional environment variables" do
            pipeline_creator.create

            expect(generated_cng_yaml).to include({ "variables" => variables })
          end
        end
      end

      context "with unsuccessful pipeline creation" do
        context "with missing job definition in pipeline" do
          let(:cng_pipeline_definition) do
            {
              "some-other-job" => {
                "stage" => "report"
              }
            }
          end

          it "raises an error" do
            expect { pipeline_creator.create }.to raise_error(
              RuntimeError,
              "Job definition not found for job 'cng-instance' in pipeline: test_on_cng"
            )
          end
        end

        context "with unsupported pipeline type" do
          let(:scenario_class) do
            Class.new(Scenario::Template) do
              pipeline_mappings unsupported_pipeline: ['test-job']
            end
          end

          it "raises an error" do
            expect { pipeline_creator.create }.to raise_error(
              RuntimeError,
              "Scenario class '#{scenario_class}' contains unsupported pipeline type 'unsupported_pipeline'"
            )
          end
        end
      end
    end
  end
  # rubocop:enable Fips/MD5
end
