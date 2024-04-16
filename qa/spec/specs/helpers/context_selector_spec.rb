# frozen_string_literal: true

require 'rspec/core/sandbox'

RSpec.describe QA::Specs::Helpers::ContextSelector do
  include QA::Support::Helpers::StubEnv
  include QA::Specs::Helpers::RSpec

  around do |ex|
    QA::Runtime::Scenario.define(:gitlab_address, 'https://staging.gitlab.com')

    RSpec::Core::Sandbox.sandboxed do |config|
      config.formatter = QA::Support::Formatters::ContextFormatter

      # If there is an example-within-an-example, we want to make sure the inner example
      # does not get a reference to the outer example (the real spec) if it calls
      # something like `pending`
      config.before(:context) { RSpec.current_example = nil }
      config.color_mode = :off

      ex.run
    end
  end

  describe '.context_matches?' do
    it 'returns true when url has .com' do
      QA::Runtime::Scenario.define(:gitlab_address, "https://staging.gitlab.com")

      expect(described_class.dot_com?).to be_truthy
    end

    it 'returns true when url has .net' do
      allow(GitlabEdition).to receive(:jh?).and_return(false)
      QA::Runtime::Scenario.define(:gitlab_address, "https://release.gitlab.net")

      expect(described_class.context_matches?).to be_truthy
    end

    it 'returns true when url has .cn on jh side' do
      allow(GitlabEdition).to receive(:jh?).and_return(true)
      QA::Runtime::Scenario.define(:gitlab_address, "https://release.gitlab.cn")

      expect(described_class.context_matches?).to be_truthy
    end

    it 'returns false when url does not have .com' do
      QA::Runtime::Scenario.define(:gitlab_address, "https://gitlab.test")

      expect(described_class.dot_com?).to be_falsey
    end

    context 'with arguments' do
      it 'returns true when :subdomain is set' do
        QA::Runtime::Scenario.define(:gitlab_address, "https://staging.gitlab.com")

        expect(described_class.dot_com?(subdomain: :staging)).to be_truthy
      end

      it 'matches multiple subdomains' do
        allow(GitlabEdition).to receive(:jh?).and_return(false)
        QA::Runtime::Scenario.define(:gitlab_address, "https://staging.gitlab.com")

        aggregate_failures do
          expect(described_class.context_matches?(subdomain: [:release, :staging])).to be_truthy
          expect(described_class.context_matches?(:production, subdomain: [:release, :staging])).to be_truthy
        end
      end

      it 'matches multiple subdomains on jh side' do
        allow(GitlabEdition).to receive(:jh?).and_return(true)
        QA::Runtime::Scenario.define(:gitlab_address, "https://staging.jihulab.com")

        aggregate_failures do
          expect(described_class.context_matches?(subdomain: [:release, :staging])).to be_truthy
          expect(described_class.context_matches?(:production, subdomain: [:release, :staging])).to be_truthy
        end
      end

      it 'matches :production' do
        allow(GitlabEdition).to receive(:jh?).and_return(false)
        QA::Runtime::Scenario.define(:gitlab_address, "https://gitlab.com/")

        expect(described_class.context_matches?(:production)).to be_truthy
      end

      it 'matches :production on jh side' do
        allow(GitlabEdition).to receive(:jh?).and_return(true)

        QA::Runtime::Scenario.define(:gitlab_address, "https://jihulab.com/")
        expect(described_class.context_matches?(:production)).to be_truthy

        QA::Runtime::Scenario.define(:gitlab_address, "https://gitlab.hk/")
        expect(described_class.context_matches?(:production)).to be_truthy

        QA::Runtime::Scenario.define(:gitlab_address, "https://gitlab.cn/")
        expect(described_class.context_matches?(:production)).to be_truthy
      end

      it 'matches domain' do
        allow(GitlabEdition).to receive(:jh?).and_return(false)
        QA::Runtime::Scenario.define(:gitlab_address, 'https://jihulab.com')

        aggregate_failures do
          expect(described_class.context_matches?(:production)).to be_falsey
          expect(described_class.context_matches?(domain: 'gitlab')).to be_falsey
          expect(described_class.context_matches?(domain: 'jihulab')).to be_truthy
        end
      end

      it 'matches domain on jh side' do
        # To simulate run tests in JH
        allow(GitlabEdition).to receive(:jh?).and_return(true)
        QA::Runtime::Scenario.define(:gitlab_address, 'https://jihulab.com')

        aggregate_failures do
          expect(described_class.context_matches?(:production)).to be_truthy
          expect(described_class.context_matches?(domain: 'gitlab')).to be_falsey
          expect(described_class.context_matches?(domain: 'jihulab')).to be_truthy
        end

        QA::Runtime::Scenario.define(:gitlab_address, 'https://gitlab.hk')

        aggregate_failures do
          expect(described_class.context_matches?(:production)).to be_truthy
          expect(described_class.context_matches?(domain: 'jihulab')).to be_falsey
          expect(described_class.context_matches?(domain: 'gitlab')).to be_truthy
        end
      end

      it 'matches tld' do
        QA::Runtime::Scenario.define(:gitlab_address, 'https://gitlab.cn')

        aggregate_failures do
          expect(described_class.context_matches?).to be_falsey
          expect(described_class.context_matches?(tld: 'net')).to be_falsey
          expect(described_class.context_matches?(tld: 'cn')).to be_truthy
        end
      end

      it 'doesnt match with mismatching switches' do
        QA::Runtime::Scenario.define(:gitlab_address, 'https://gitlab.test')

        aggregate_failures do
          expect(described_class.context_matches?(tld: '.net')).to be_falsey
          expect(described_class.context_matches?(:production)).to be_falsey
          expect(described_class.context_matches?(subdomain: [:staging])).to be_falsey
          expect(described_class.context_matches?(domain: 'example')).to be_falsey
        end
      end
    end

    context 'with generic condition context matcher' do
      it 'matches truthy lambda condition result' do
        expect(described_class.context_matches?(condition: -> { true })).to be_truthy
      end

      it 'matches truthy condition result' do
        expect(described_class.context_matches?(condition: true)).to be_truthy
      end

      it 'skips falsey condition result' do
        expect(described_class.context_matches?(condition: false)).to be_falsey
      end
    end

    it 'returns false for mismatching' do
      QA::Runtime::Scenario.define(:gitlab_address, "https://staging.gitlab.com")

      expect(described_class.context_matches?(:production)).to be_falsey
    end
  end

  describe 'description and context blocks' do
    context 'with environment set' do
      it 'can apply to contexts or descriptions' do
        group = describe_successfully 'Runs in staging', only: { subdomain: :staging } do
          it('runs in staging') {}
        end

        expect(group.examples[0].execution_result.status).to eq(:passed)
      end

      context 'when excluding contexts' do
        it 'can apply to contexts or descriptions' do
          group = describe_successfully 'skips staging', except: { subdomain: :staging } do
            it('skips staging') {}
          end

          expect(group.examples[0].execution_result.status).to eq(:pending)
        end
      end
    end

    context 'with different environment set' do
      before do
        allow(GitlabEdition).to receive(:jh?).and_return(false)
        QA::Runtime::Scenario.define(:gitlab_address, 'https://gitlab.com')
      end

      it 'does not run against production' do
        group = describe_successfully 'Runs in staging', :something, only: { subdomain: :staging } do
          it('runs in staging') {}
        end

        expect(group.examples[0].execution_result.status).to eq(:pending)
      end

      context 'when excluding contexts' do
        it 'runs against production' do
          group = describe_successfully 'Runs in staging', :something, except: { subdomain: :staging } do
            it('runs in staging') {}
          end

          expect(group.examples[0].execution_result.status).to eq(:passed)
        end
      end
    end

    context 'with different environment set on jh side' do
      before do
        allow(GitlabEdition).to receive(:jh?).and_return(true)
        QA::Runtime::Scenario.define(:gitlab_address, 'https://jihulab.com')
      end

      it 'does not run against production' do
        group = describe_successfully 'Runs in staging', :something, only: { subdomain: :staging } do
          it('runs in staging') {}
        end

        expect(group.examples[0].execution_result.status).to eq(:pending)
      end

      context 'when excluding contexts' do
        it 'runs against production' do
          group = describe_successfully 'Runs in staging', :something, except: { subdomain: :staging } do
            it('runs in staging') {}
          end

          expect(group.examples[0].execution_result.status).to eq(:passed)
        end
      end
    end
  end

  it 'runs only in staging' do
    group = describe_successfully do
      it('runs in staging', only: { subdomain: :staging }) {}
      it('doesnt run in staging', only: :production) {}
      it('runs in staging also', only: { subdomain: %i[release staging] }) {}
      it('runs in any env') {}
    end

    aggregate_failures do
      expect(group.examples[0].execution_result.status).to eq(:passed)
      expect(group.examples[1].execution_result.status).to eq(:pending)
      expect(group.examples[2].execution_result.status).to eq(:passed)
      expect(group.examples[3].execution_result.status).to eq(:passed)
    end
  end

  context 'when excluding contexts' do
    it 'skips staging' do
      group = describe_successfully do
        it('skips staging', except: { subdomain: :staging }) {}
        it('runs in staging', except: :production) {}
        it('skips staging also', except: { subdomain: %i[release staging] }) {}
      end

      aggregate_failures do
        expect(group.examples[0].execution_result.status).to eq(:pending)
        expect(group.examples[1].execution_result.status).to eq(:passed)
        expect(group.examples[2].execution_result.status).to eq(:pending)
      end
    end
  end

  context 'custom env' do
    before do
      QA::Runtime::Scenario.define(:gitlab_address, 'https://release.gitlab.net')
    end

    it 'runs on a custom environment' do
      group = describe_successfully do
        it('runs on release gitlab net', only: { tld: '.net', subdomain: :release, domain: 'gitlab' }) {}
        it('does not run on release', only: :production) {}
      end

      aggregate_failures do
        expect(group.examples.first.execution_result.status).to eq(:passed)
        expect(group.examples.last.execution_result.status).to eq(:pending)
      end
    end

    context 'when excluding contexts' do
      it 'skips a custom environment' do
        group = describe_successfully do
          it('skips release gitlab net', except: { tld: '.net', subdomain: :release, domain: 'gitlab' }) {}
          it('runs on release', except: :production) {}
        end

        aggregate_failures do
          expect(group.examples.first.execution_result.status).to eq(:pending)
          expect(group.examples.last.execution_result.status).to eq(:passed)
        end
      end
    end
  end

  context 'staging-ref' do
    before do
      QA::Runtime::Scenario.define(:gitlab_address, 'https://staging-ref.gitlab.com/')
    end

    it 'runs on staging-ref' do
      group = describe_successfully do
        it('does not run in staging', only: { subdomain: :staging }) {}
        it('runs in staging-ref', only: { subdomain: /^staging-ref./ }) {}
      end

      aggregate_failures do
        expect(group.examples[0].execution_result.status).to eq(:pending)
        expect(group.examples[1].execution_result.status).to eq(:passed)
      end
    end
  end

  context 'local' do
    it 'runs locally' do
      stub_env('CI', 'true')
      stub_env('CI_JOB_NAME', nil)

      group = describe_successfully 'Runs locally', :local do
        it('runs locally') {}
      end

      expect(group.examples[0].execution_result.status).to eq(:passed)
    end

    it 'does not run in CI' do
      stub_env('CI', 'true')
      stub_env('CI_JOB_NAME', 'ee:instance-image')

      group = describe_successfully 'Does not run in CI' do
        it('does not run in CI', only: :local) {}
      end

      expect(group.examples[0].execution_result.status).to eq(:pending)
    end
  end

  context 'production' do
    before do
      allow(GitlabEdition).to receive(:jh?).and_return(false)
      QA::Runtime::Scenario.define(:gitlab_address, 'https://gitlab.com/')
    end

    it 'runs on production' do
      group = describe_successfully do
        it('runs on prod', only: :production) {}
        it('does not run in prod', only: { subdomain: :staging }) {}
        it('runs in prod and staging', only: { subdomain: /(staging.)?/, domain: 'gitlab' }) {}
      end

      aggregate_failures do
        expect(group.examples[0].execution_result.status).to eq(:passed)
        expect(group.examples[1].execution_result.status).to eq(:pending)
        expect(group.examples[2].execution_result.status).to eq(:passed)
      end
    end

    context 'when excluding contexts' do
      it 'skips production' do
        group = describe_successfully do
          it('skips prod', except: :production) {}
          it('runs on prod', except: { subdomain: :staging }) {}
          it('skips prod and staging', except: { subdomain: /(staging.)?/, domain: 'gitlab' }) {}
        end

        aggregate_failures do
          expect(group.examples[0].execution_result.status).to eq(:pending)
          expect(group.examples[1].execution_result.status).to eq(:passed)
          expect(group.examples[2].execution_result.status).to eq(:pending)
        end
      end
    end
  end

  context 'jh mainland production ' do
    before do
      allow(GitlabEdition).to receive(:jh?).and_return(true)
      QA::Runtime::Scenario.define(:gitlab_address, 'https://jihulab.com/')
    end

    it 'runs on production' do
      group = describe_successfully do
        it('runs on prod', only: :production) {}
        it('does not run in prod', only: { subdomain: :staging }) {}
        it('runs in prod and staging', only: { subdomain: /(staging.)?/, domain: 'jihulab' }) {}
      end

      aggregate_failures do
        expect(group.examples[0].execution_result.status).to eq(:passed)
        expect(group.examples[1].execution_result.status).to eq(:pending)
        expect(group.examples[2].execution_result.status).to eq(:passed)
      end
    end

    context 'when excluding contexts' do
      it 'skips production' do
        group = describe_successfully do
          it('skips prod', except: :production) {}
          it('runs on prod', except: { subdomain: :staging }) {}
          it('skips prod and staging', except: { subdomain: /(staging.)?/, domain: 'jihulab' }) {}
        end

        aggregate_failures do
          expect(group.examples[0].execution_result.status).to eq(:pending)
          expect(group.examples[1].execution_result.status).to eq(:passed)
          expect(group.examples[2].execution_result.status).to eq(:pending)
        end
      end
    end
  end

  context 'jh hk production ' do
    before do
      allow(GitlabEdition).to receive(:jh?).and_return(true)
      QA::Runtime::Scenario.define(:gitlab_address, 'https://gitlab.hk/')
    end

    it 'runs on production' do
      group = describe_successfully do
        it('runs on prod', only: :production) {}
        it('does not run in prod', only: { subdomain: :staging }) {}
        it('runs in prod and staging', only: { subdomain: /(staging.)?/, domain: 'gitlab' }) {}
      end

      aggregate_failures do
        expect(group.examples[0].execution_result.status).to eq(:passed)
        expect(group.examples[1].execution_result.status).to eq(:pending)
        expect(group.examples[2].execution_result.status).to eq(:passed)
      end
    end

    context 'when excluding contexts' do
      it 'skips production' do
        group = describe_successfully do
          it('skips prod', except: :production) {}
          it('runs on prod', except: { subdomain: :staging }) {}
          it('skips prod and staging', except: { subdomain: /(staging.)?/, domain: 'gitlab' }) {}
        end

        aggregate_failures do
          expect(group.examples[0].execution_result.status).to eq(:pending)
          expect(group.examples[1].execution_result.status).to eq(:passed)
          expect(group.examples[2].execution_result.status).to eq(:pending)
        end
      end
    end
  end

  it 'outputs a message for invalid environments' do
    group = describe_successfully do
      it('will skip', only: :production) {}
    end

    expect(group.examples.first.execution_result.pending_message).to match(/[Tt]est.*not compatible.*environment/)
  end

  context 'with pipeline constraints' do
    context 'without CI_PROJECT_NAME set' do
      before do
        stub_env('CI_PROJECT_NAME', nil)
      end

      it 'runs on any pipeline' do
        group = describe_successfully do
          it('runs given a single named pipeline', only: { pipeline: :nightly }) {}
          it('runs given an array of pipelines', only: { pipeline: [:canary, :not_nightly] }) {}
        end

        aggregate_failures do
          expect(group.examples[0].execution_result.status).to eq(:passed)
          expect(group.examples[1].execution_result.status).to eq(:passed)
        end
      end

      context 'when excluding contexts' do
        it 'runs in any pipeline' do
          group = describe_successfully do
            it('runs given a single named pipeline', except: { pipeline: :nightly }) {}
            it('runs given an array of pipelines', except: { pipeline: [:canary, :not_nightly] }) {}
          end

          aggregate_failures do
            group.examples.each do |example|
              expect(example.execution_result.status).to eq(:passed)
            end
          end
        end
      end
    end

    context 'when a pipeline triggered from the default branch runs in gitlab-qa' do
      before do
        stub_env('CI_PROJECT_NAME', 'gitlab-qa')
      end

      it 'runs on default branch pipelines' do
        group = describe_successfully do
          it('runs on main pipeline given a single pipeline', only: { pipeline: :main }) {}
          it('runs in main given an array of pipelines', only: { pipeline: [:canary, :main] }) {}
          it('does not run in non-default pipelines', only: { pipeline: [:nightly, :not_nightly, :not_main] }) {}
        end

        aggregate_failures do
          expect(group.examples[0].execution_result.status).to eq(:passed)
          expect(group.examples[1].execution_result.status).to eq(:passed)
          expect(group.examples[2].execution_result.status).to eq(:pending)
        end
      end

      context 'when excluding contexts' do
        it 'skips default branch pipelines' do
          group = describe_successfully do
            it('skips main pipeline given a single pipeline', except: { pipeline: :main }) {}
            it('skips main given an array of pipelines', except: { pipeline: [:canary, :main] }) {}
            it('runs non-default pipelines', except: { pipeline: [:nightly, :not_nightly, :not_main] }) {}
          end

          aggregate_failures do
            expect(group.examples[0].execution_result.status).to eq(:pending)
            expect(group.examples[1].execution_result.status).to eq(:pending)
            expect(group.examples[2].execution_result.status).to eq(:passed)
          end
        end
      end
    end

    context 'with CI_PROJECT_NAME set' do
      before do
        stub_env('CI_PROJECT_NAME', 'NIGHTLY')
      end

      it 'runs on designated pipeline' do
        group = describe_successfully do
          it('runs on nightly', only: { pipeline: :nightly }) {}
          it('does not run in not_nightly', only: { pipeline: :not_nightly }) {}
          it('runs on nightly given an array', only: { pipeline: [:canary, :nightly] }) {}
          it('does not run in not_nightly given an array', only: { pipeline: [:not_nightly, :canary] }) {}
        end

        aggregate_failures do
          expect(group.examples[0].execution_result.status).to eq(:passed)
          expect(group.examples[1].execution_result.status).to eq(:pending)
          expect(group.examples[2].execution_result.status).to eq(:passed)
          expect(group.examples[3].execution_result.status).to eq(:pending)
        end
      end

      context 'when excluding contexts' do
        it 'skips designated pipeline' do
          group = describe_successfully do
            it('skips nightly', except: { pipeline: :nightly }) {}
            it('runs in not_nightly', except: { pipeline: :not_nightly }) {}
            it('skips on nightly given an array', except: { pipeline: [:canary, :nightly] }) {}
            it('runs in not_nightly given an array', except: { pipeline: [:not_nightly, :canary] }) {}
          end

          aggregate_failures do
            expect(group.examples[0].execution_result.status).to eq(:pending)
            expect(group.examples[1].execution_result.status).to eq(:passed)
            expect(group.examples[2].execution_result.status).to eq(:pending)
            expect(group.examples[3].execution_result.status).to eq(:passed)
          end
        end
      end
    end

    context 'with CI_PROJECT_NAME set to gitlab and SCHEDULE_TYPE set to nightly' do
      before do
        stub_env('CI_PROJECT_NAME', 'gitlab')
        stub_env('SCHEDULE_TYPE', 'nightly')
      end

      it 'runs on designated pipeline' do
        group = describe_successfully do
          it('runs on nightly', only: { pipeline: :nightly }) {}
          it('does not run in not_nightly', only: { pipeline: :not_nightly }) {}
          it('runs on nightly given an array', only: { pipeline: [:canary, :nightly] }) {}
          it('does not run in not_nightly given an array', only: { pipeline: [:not_nightly, :canary] }) {}
        end

        aggregate_failures do
          expect(group.examples[0].execution_result.status).to eq(:passed)
          expect(group.examples[1].execution_result.status).to eq(:pending)
          expect(group.examples[2].execution_result.status).to eq(:passed)
          expect(group.examples[3].execution_result.status).to eq(:pending)
        end
      end

      context 'when excluding contexts' do
        it 'skips designated pipeline' do
          group = describe_successfully do
            it('skips nightly', except: { pipeline: :nightly }) {}
            it('runs in not_nightly', except: { pipeline: :not_nightly }) {}
            it('skips on nightly given an array', except: { pipeline: [:canary, :nightly] }) {}
            it('runs in not_nightly given an array', except: { pipeline: [:not_nightly, :canary] }) {}
          end

          aggregate_failures do
            expect(group.examples[0].execution_result.status).to eq(:pending)
            expect(group.examples[1].execution_result.status).to eq(:passed)
            expect(group.examples[2].execution_result.status).to eq(:pending)
            expect(group.examples[3].execution_result.status).to eq(:passed)
          end
        end
      end
    end
  end

  context 'with job constraints' do
    context 'without CI_JOB_NAME set' do
      before do
        stub_env('CI_JOB_NAME', nil)
      end

      context 'when excluding contexts' do
        it 'runs in any job' do
          group = describe_successfully do
            it('runs given a single named job', except: { job: 'ee:instance-image' }) {}
            it('runs given a single regex pattern', except: { job: '.*:instance-image' }) {}
            it('runs given an array of jobs', except: { job: %w[ee:instance-image qa-schedules-browser_ui-3_create] }) {}
            it('runs given an array of regex patterns', except: { job: %w[ee:.* qa-schedules-browser_ui.*] }) {}
            it('runs given a mix of strings and regex patterns', except: { job: %w[ee:instance-image qa-schedules-browser_ui.*] }) {}
          end

          aggregate_failures do
            group.examples.each do |example|
              expect(example.execution_result.status).to eq(:passed)
            end
          end
        end
      end

      context 'when including only specific contexts' do
        it 'runs in any job' do
          group = describe_successfully do
            it('runs given a single named job', only: { job: 'ee:instance-image' }) {}
            it('runs given a single regex pattern', only: { job: '.*:instance-image' }) {}
            it('runs given an array of jobs', only: { job: %w[ee:instance-image qa-schedules-browser_ui-3_create] }) {}
            it('runs given an array of regex patterns', only: { job: %w[ee:.* qa-schedules-browser_ui.*] }) {}
            it('runs given a mix of strings and regex patterns', only: { job: %w[ee:instance-image qa-schedules-browser_ui.*] }) {}
          end

          aggregate_failures do
            group.examples.each do |example|
              expect(example.execution_result.status).to eq(:passed)
            end
          end
        end
      end
    end

    context 'with CI_JOB_NAME set' do
      before do
        stub_env('CI_JOB_NAME', 'ee:instance-image')
      end

      context 'when excluding contexts' do
        it 'does not run in the specified job' do
          group = describe_successfully do
            it('skips given a single named job', except: { job: 'ee:instance-image' }) {}
            it('skips given a single regex pattern', except: { job: '.*:instance-image' }) {}
            it('skips given an array of jobs', except: { job: %w[ee:instance-image qa-schedules-browser_ui-3_create] }) {}
            it('skips given an array of regex patterns', except: { job: %w[ee:.* qa-schedules-browser_ui.*] }) {}
            it('skips given a mix of strings and regex patterns', except: { job: %w[ee:instance-image qa-schedules-browser_ui.*] }) {}
          end

          aggregate_failures do
            group.examples.each do |example|
              expect(example.execution_result.status).to eq(:pending)
            end
          end
        end

        it 'runs in jobs that do not match' do
          group = describe_successfully do
            it('runs given a single named job', except: { job: 'ce:instance-image' }) {}
            it('runs given a single regex pattern', except: { job: '.*:instance-image-quarantine' }) {}
            it('runs given an array of jobs', except: { job: %w[ce:instance-image qa-schedules-browser_ui-3_create] }) {}
            it('runs given an array of regex patterns', except: { job: %w[ce:.* qa-schedules-browser_ui.*] }) {}
            it('runs given a mix of strings and regex patterns', except: { job: %w[ce:instance-image qa-schedules-browser_ui.*] }) {}
          end

          aggregate_failures do
            group.examples.each do |example|
              expect(example.execution_result.status).to eq(:passed)
            end
          end
        end
      end

      context 'when including only specific contexts' do
        it 'runs only in the specified jobs' do
          group = describe_successfully do
            it('runs given a single named job', only: { job: 'ee:instance-image' }) {}
            it('runs given a single regex pattern', only: { job: '.*:instance-image' }) {}
            it('runs given an array of jobs', only: { job: %w[ee:instance-image qa-schedules-browser_ui-3_create] }) {}
            it('runs given an array of regex patterns', only: { job: %w[ee:.* qa-schedules-browser_ui.*] }) {}
            it('runs given a mix of strings and regex patterns', only: { job: %w[ee:instance-image qa-schedules-browser_ui.*] }) {}
          end

          aggregate_failures do
            group.examples.each do |example|
              expect(example.execution_result.status).to eq(:passed)
            end
          end
        end

        it 'does not run in jobs that do not match' do
          group = describe_successfully do
            it('skips given a single named job', only: { job: 'ce:instance-image' }) {}
            it('skips given a single regex pattern', only: { job: '.*:instance-image-quarantine' }) {}
            it('skips given an array of jobs', only: { job: %w[ce:instance-image qa-schedules-browser_ui-3_create] }) {}
            it('skips given an array of regex patterns', only: { job: %w[ce:.* qa-schedules-browser_ui.*] }) {}
            it('skips given a mix of strings and regex patterns', only: { job: %w[ce:instance-image qa-schedules-browser_ui.*] }) {}
          end

          aggregate_failures do
            group.examples.each do |example|
              expect(example.execution_result.status).to eq(:pending)
            end
          end
        end
      end
    end
  end
end
