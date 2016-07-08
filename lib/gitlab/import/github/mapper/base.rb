module Gitlab
  module Import
    module Github
      module Mapper
        class Base
          def initialize(project, client)
            @project = project
            @client  = client
          end

          def each
            return enum_for(:each) unless block_given?

            method = klass.to_s.underscore.pluralize

            client.public_send(method).each do |raw|
              yield(klass.new(attributes_for(raw)))
            end
          end

          private

          attr_reader :project, :client

          def attributes_for
            {}
          end

          def klass
            raise NotImplementedError,
              "#{self.class} does not implement #{__method__}"
          end
        end
      end
    end
  end
end
