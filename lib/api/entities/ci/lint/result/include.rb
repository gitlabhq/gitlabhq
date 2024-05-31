# frozen_string_literal: true

module API
  module Entities
    module Ci
      module Lint
        class Result
          class Include < Grape::Entity
            expose :type, as: :type,
              documentation: { type: 'string', example: 'local' }
            expose :location, as: :location,
              documentation: { type: 'string', example: '.gitlab/ci/build-images.gitlab-ci.yml' }
            expose :blob, as: :blob,
              documentation: { type: 'string', example: 'https://gitlab.com/gitlab-org/gitlab/-/blob/e52d6d0246d7375291850e61f0abc101fbda9dc2/.gitlab/ci/build-images.gitlab-ci.yml' }
            expose :raw, as: :raw,
              documentation: { type: 'string', example: 'https://gitlab.com/gitlab-org/gitlab/-/raw/e52d6d0246d7375291850e61f0abc101fbda9dc2/.gitlab/ci/build-images.gitlab-ci.yml' }
            expose :extra, as: :extra,
              documentation: { type: 'object',
                               example: '{ "job_name": "test", "project": "gitlab-org/gitlab", "ref": "master" }' }
            expose :context_project, as: :context_project,
              documentation: { type: 'string', example: 'gitlab-org/gitlab' }
            expose :context_sha, as: :context_sha,
              documentation: { type: 'string', example: 'e52d6d0246d7375291850e61f0abc101fbda9dc2' }
          end
        end
      end
    end
  end
end
