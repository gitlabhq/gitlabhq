# frozen_string_literal: true

# Timestamp is set to `20260305214248` so that this is executed
# right after `20260305214247` which may introduce the problem for
# instances that have incorrect sequence owner.
class EnsureUploadsIdDefault < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def up
    change_column_default :uploads, :id,
      from: -> { "nextval('uploads_id_seq'::regclass)" },
      to: -> { "nextval('uploads_id_seq'::regclass)" }

    execute 'ALTER SEQUENCE uploads_id_seq OWNED BY uploads.id'
  end

  def down
    # no-op
  end
end
