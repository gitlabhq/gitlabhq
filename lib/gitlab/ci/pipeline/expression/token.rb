module Gitlab
  module Ci
    module Pipeline
      module Expression
        class Token
          def evaluate(**variables)
            raise NotImplementedError
          end

          def self.build(string)
            raise NotImplementedError
          end

          def self.scan(scanner)
            scanner.scan(PATTERN)
          end
        end
      end
    end
  end
end
