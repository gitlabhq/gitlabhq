# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'factories' do
  include Database::DatabaseHelpers

  # https://gitlab.com/groups/gitlab-org/-/epics/5464 tracks the remaining
  # skipped traits.
  #
  # Consider adding a code comment if a trait cannot produce a valid object.
  def skipped_traits
    [
      [:audit_event, :unauthenticated],
      [:ci_build_trace_chunk, :fog_with_data],
      [:ci_job_artifact, :remote_store],
      [:ci_job_artifact, :raw],
      [:ci_job_artifact, :gzip],
      [:ci_job_artifact, :correct_checksum],
      [:environment, :non_playable],
      [:composer_cache_file, :object_storage],
      [:debian_project_component_file, :object_storage],
      [:debian_project_distribution, :object_storage],
      [:debian_file_metadatum, :unknown],
      [:package_file, :object_storage],
      [:pages_domain, :without_certificate],
      [:pages_domain, :without_key],
      [:pages_domain, :with_missing_chain],
      [:pages_domain, :with_trusted_chain],
      [:pages_domain, :with_trusted_expired_chain],
      [:pages_domain, :explicit_ecdsa],
      [:project_member, :blocked],
      [:project, :remote_mirror],
      [:remote_mirror, :ssh],
      [:user_preference, :only_comments],
      [:ci_pipeline_artifact, :remote_store]
    ]
  end

  shared_examples 'factory' do |factory|
    describe "#{factory.name} factory" do
      it 'does not raise error when built' do
        expect { build(factory.name) }.not_to raise_error
      end

      it 'does not raise error when created' do
        expect { create(factory.name) }.not_to raise_error # rubocop:disable Rails/SaveBang
      end

      factory.definition.defined_traits.map(&:name).each do |trait_name|
        describe "linting :#{trait_name} trait" do
          it 'does not raise error when created' do
            pending("Trait skipped linting due to legacy error") if skipped_traits.include?([factory.name, trait_name.to_sym])

            expect { create(factory.name, trait_name) }.not_to raise_error
          end
        end
      end
    end
  end

  # FactoryDefault speed up specs by creating associations only once
  # and reuse them in other factories.
  #
  # However, for some factories we cannot use FactoryDefault because the
  # associations must be unique and cannot be reused, or the factory default
  # is being mutated.
  skip_factory_defaults = %i[
    ci_job_token_project_scope_link
    evidence
    exported_protected_branch
    fork_network_member
    group_member
    import_state
    milestone_release
    namespace
    project_broken_repo
    project_repository
    prometheus_alert
    prometheus_alert_event
    prometheus_metric
    protected_branch
    protected_branch_merge_access_level
    protected_branch_push_access_level
    protected_tag
    release
    release_link
    self_managed_prometheus_alert_event
    shard
    users_star_project
    wiki_page
    wiki_page_meta
  ].to_set.freeze

  # Some factories and their corresponding models are based on
  # database views. In order to use those, we have to swap the
  # view out with a table of the same structure.
  factories_based_on_view = %i[
    postgres_index
    postgres_index_bloat_estimate
  ].to_set.freeze

  without_fd, with_fd = FactoryBot.factories
    .partition { |factory| skip_factory_defaults.include?(factory.name) }

  context 'with factory defaults', factory_default: :keep do
    let_it_be(:namespace) { create_default(:namespace).freeze }
    let_it_be(:project) { create_default(:project, :repository).freeze }
    let_it_be(:user) { create_default(:user).freeze }

    before do
      factories_based_on_view.each do |factory|
        view = build(factory).class.table_name
        swapout_view_for_table(view)
      end
    end

    with_fd.each do |factory|
      it_behaves_like 'factory', factory
    end
  end

  context 'without factory defaults' do
    without_fd.each do |factory|
      it_behaves_like 'factory', factory
    end
  end
end
