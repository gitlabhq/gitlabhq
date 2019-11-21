# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module KubectlCmd
      class << self
        def delete(*args)
          %w(kubectl delete).concat(args).shelljoin
        end

        def apply_file(filename, *args)
          raise ArgumentError, "filename is not present" unless filename.present?

          %w(kubectl apply -f).concat([filename], args).shelljoin
        end

        def delete_crds_from_group(group)
          api_resources_args = %w(-o name --api-group).push(group)

          api_resources(*api_resources_args) + " | xargs " + delete('--ignore-not-found', 'crd')
        end

        def api_resources(*args)
          %w(kubectl api-resources).concat(args).shelljoin
        end
      end
    end
  end
end
