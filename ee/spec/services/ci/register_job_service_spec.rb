require 'spec_helper'

describe Ci::RegisterJobService do
  let!(:project) { create :project, shared_runners_enabled: false }
  let!(:pipeline) { create :ci_empty_pipeline, project: project }
  let!(:pending_build) { create :ci_build, pipeline: pipeline }
  let(:shared_runner) { create(:ci_runner, :instance) }

  describe '#execute' do
    context 'for project with shared runners when global minutes limit is set' do
      before do
        project.update(shared_runners_enabled: true)
        stub_application_setting(shared_runners_minutes: 100)
      end

      context 'allow to pick builds' do
        let(:build) { execute(shared_runner) }

        it { expect(build).to be_kind_of(Ci::Build) }
      end

      context 'when over the global quota' do
        before do
          project.namespace.create_namespace_statistics(
            shared_runners_seconds: 6001)
        end

        let(:build) { execute(shared_runner) }

        it "does not return a build" do
          expect(build).to be_nil
        end

        context 'when project is public' do
          before do
            project.update(visibility_level: Project::PUBLIC)
          end

          it "does return the build" do
            expect(build).to be_kind_of(Ci::Build)
          end
        end

        context 'when namespace limit is set to unlimited' do
          before do
            project.namespace.update(shared_runners_minutes_limit: 0)
          end

          it "does return the build" do
            expect(build).to be_kind_of(Ci::Build)
          end
        end

        context 'when namespace quota is bigger than a global one' do
          before do
            project.namespace.update(shared_runners_minutes_limit: 101)
          end

          it "does return the build" do
            expect(build).to be_kind_of(Ci::Build)
          end
        end
      end

      context 'when group is subgroup' do
        let!(:root_ancestor) { create(:group) }
        let!(:group) { create(:group, parent: root_ancestor) }
        let!(:project) { create :project, shared_runners_enabled: true, group: group }
        let(:build) { execute(shared_runner) }

        context 'when shared_runner_minutes_on_root_namespace is disabled' do
          before do
            stub_feature_flags(shared_runner_minutes_on_root_namespace: false)
          end

          it "does return a build" do
            expect(build).not_to be_nil
          end

          context 'when we are over limit on subnamespace' do
            before do
              group.create_namespace_statistics(
                shared_runners_seconds: 6001)
            end

            it "does not return a build" do
              expect(build).to be_nil
            end
          end
        end

        context 'when shared_runner_minutes_on_root_namespace is enabled', :nested_groups do
          before do
            stub_feature_flags(shared_runner_minutes_on_root_namespace: true)
          end

          it "does return a build" do
            expect(build).not_to be_nil
          end

          context 'when we are over limit on subnamespace' do
            before do
              group.create_namespace_statistics(
                shared_runners_seconds: 6001)
            end

            it "limit is ignored and build is returned" do
              expect(build).not_to be_nil
            end
          end

          context 'when we are over limit on root namespace' do
            before do
              root_ancestor.create_namespace_statistics(
                shared_runners_seconds: 6001)
            end

            it "does not return a build" do
              expect(build).to be_nil
            end
          end
        end
      end
    end

    def execute(runner)
      described_class.new(runner).execute.build
    end
  end
end
