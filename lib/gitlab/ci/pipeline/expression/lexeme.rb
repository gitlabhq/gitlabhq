module Gitlab
  module Ci
    module Pipeline
      module Expression
        class Lexeme
          def evaluate(**variables)
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
