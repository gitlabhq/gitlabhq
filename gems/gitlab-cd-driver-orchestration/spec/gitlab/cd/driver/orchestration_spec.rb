# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Cd::Driver::Orchestration do
  describe ".gem_name_to_identifier" do
    it "escapes dashes to _d" do
      expect(described_class.gem_name_to_identifier("gitlab-deploy-driver-argo-rollouts"))
        .to eq("gitlab_ddeploy_ddriver_dargo_drollouts")
    end

    it "doubles existing underscores before other escapes so they stay unambiguous" do
      expect(described_class.gem_name_to_identifier("gitlab-safe_request_store"))
        .to eq("gitlab_dsafe__request__store")
    end

    it "escapes dots to _p" do
      expect(described_class.gem_name_to_identifier("a.b")).to eq("a_pb")
    end

    it "prefixes an underscore when the result starts with a digit" do
      expect(described_class.gem_name_to_identifier("1password")).to eq("_1password")
    end

    it "distinguishes names that differ only by dash vs underscore" do
      expect(described_class.gem_name_to_identifier("a-b"))
        .not_to eq(described_class.gem_name_to_identifier("a_b"))
    end
  end

  describe ".assemble" do
    let(:driver_script) do
      <<~STAR
        def deploy():
            def canary_deploy(step, environment, services, version_set):
                pass
            register("com.gitlab.cd.argo.canary.deploy", run = canary_deploy)
      STAR
    end

    subject(:program) do
      described_class.assemble(driver_scripts: { "gitlab-deploy-driver-argo-rollouts" => driver_script })
    end

    it "prepends the orchestrator engine before the driver fragment" do
      expect(program).to include("def main(")
      expect(program.index("def main(")).to be < program.index("gitlab_ddeploy_ddriver_dargo_drollouts_deploy")
    end

    it "renames the driver's module-level deploy() to a gem-unique identifier" do
      expect(program).to include("def gitlab_ddeploy_ddriver_dargo_drollouts_deploy():")
      expect(program).not_to include("\ndef deploy(")
    end

    it "invokes each renamed deploy() at module level so registration runs before main()" do
      expect(program).to match(/^gitlab_ddeploy_ddriver_dargo_drollouts_deploy\(\)$/)
    end

    it "returns a binary-encoded string, as KAS expects" do
      expect(program.encoding).to eq(Encoding::ASCII_8BIT)
    end

    it "raises when a driver script has no module-level def deploy(" do
      expect { described_class.assemble(driver_scripts: { "x" => "def other():\n    pass\n" }) }
        .to raise_error(ArgumentError, /no module-level `def deploy\(`/)
    end

    context "when a driver fragment redeclares an engine global" do
      it "raises naming the colliding def" do
        script = "def gl_run(function, inputs):\n    pass\n\ndef deploy():\n    pass\n"

        expect { described_class.assemble(driver_scripts: { "x" => script }) }
          .to raise_error(ArgumentError, /x redeclares globals the orchestration engine owns: gl_run/)
      end

      it "raises naming the colliding assignment" do
        script = "_STAGE_TYPE = \"other\"\n\ndef deploy():\n    pass\n"

        expect { described_class.assemble(driver_scripts: { "x" => script }) }
          .to raise_error(ArgumentError, /redeclares globals .*: _STAGE_TYPE/)
      end

      it "raises when a load() rebinds a name the engine's own load() binds" do
        script = "load(\"module:gitlab-function\", gitlab_function_run = \"run\")\n\ndef deploy():\n    pass\n"

        expect { described_class.assemble(driver_scripts: { "x" => script }) }
          .to raise_error(ArgumentError, /redeclares globals .*: gitlab_function_run/)
      end

      it "names every collision, sorted, so one pass fixes them all" do
        script = <<~STAR
          load("module:gitlab-function", gitlab_function_run = "run")

          def gl_run(function, inputs):
              pass

          def _require(kwargs, name):
              pass

          def deploy():
              pass
        STAR

        expect { described_class.assemble(driver_scripts: { "x" => script }) }
          .to raise_error(ArgumentError, /: _require, gitlab_function_run, gl_run\./)
      end
    end

    it "allows a fragment-local binding that shadows nothing at module level" do
      script = "def deploy():\n    gl_run = 1\n    main = 2\n    return gl_run + main\n"

      expect { described_class.assemble(driver_scripts: { "x" => script }) }.not_to raise_error
    end

    it "allows a load() of another module under a name the engine does not own" do
      script = "load(\"module:other\", other_run = \"run\")\n\ndef deploy():\n    pass\n"

      expect { described_class.assemble(driver_scripts: { "x" => script }) }.not_to raise_error
    end
  end

  describe "ENGINE_GLOBALS" do
    it "matches the module-level globals main.star binds" do
      expect(described_class::ENGINE_GLOBALS.sort)
        .to eq(described_class.fragment_globals(described_class.main_program).sort)
    end

    it "matches the names the README tells a driver author are taken" do
      expect(readme_bound_globals).to eq(described_class::ENGINE_GLOBALS.sort)
    end
  end

  # The sentence a driver author reads to find out which names are free. Parenthetical
  # asides are dropped: they say how a name is bound, not that it is.
  def readme_bound_globals
    readme = File.read(File.expand_path("../../../../README.md", __dir__))
    sentence = readme[/The engine binds (.*?)\.\n/m, 1]

    sentence.gsub(/\([^)]*\)/, "").scan(/`(\w+)`/).flatten.sort
  end
end
