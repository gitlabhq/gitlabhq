# frozen_string_literal: true

# This module is used to augment the GCS signed URL with metadata that is used for auditing purposes.
# The uploader that includes this module should respond to `group` or `project` methods.
# If the underlying model instance does not have the `size` stored in the DB, we will make a stats request
# to fetch the file size from the object storage.
module Packages
  module GcsSignedUrlMetadata
    def url(*args, **kwargs)
      return super unless fog_credentials[:provider] == 'Google' && Gitlab.com? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- As per https://gitlab.com/groups/gitlab-org/-/epics/8834, we are only interested in egress traffic on Gitlab.com

      project = model.try(:project)
      root_namespace = project&.root_namespace || model.try(:group)&.root_ancestor

      metadata_params = {
        'x-goog-custom-audit-gitlab-project' => project&.id,
        'x-goog-custom-audit-gitlab-namespace' => root_namespace&.id,
        'x-goog-custom-audit-gitlab-size-bytes' => model.try(:size) || size
      }.compact.transform_values(&:to_s)

      super(*args, **kwargs.deep_merge(query: metadata_params))
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(
        e,
        model_class: model.class.name,
        model_id: model.id
      )
      super
    end
  end
end
