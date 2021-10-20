# frozen_string_literal: true

class NextTraversalIdsSiblingFunction < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::SchemaHelpers

  FUNCTION_NAME = 'next_traversal_ids_sibling'

  def up
    # Given array [1,2,3,4,5], concatenate the first part of the array [1,2,3,4]
    # with the last element in the array (5) after being incremented ([6]).
    #
    # [1,2,3,4,5] => [1,2,3,4,6]
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{FUNCTION_NAME}(traversal_ids INT[]) RETURNS INT[]
      AS $$
      BEGIN
        return traversal_ids[1:array_length(traversal_ids, 1)-1] ||
        ARRAY[traversal_ids[array_length(traversal_ids, 1)]+1];
      END;
      $$
      LANGUAGE plpgsql
      IMMUTABLE
      RETURNS NULL ON NULL INPUT;
    SQL
  end

  def down
    execute("DROP FUNCTION #{FUNCTION_NAME}(traversal_ids INT[])")
  end
end
