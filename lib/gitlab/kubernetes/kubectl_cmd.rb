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
      end
    end
  end
end
