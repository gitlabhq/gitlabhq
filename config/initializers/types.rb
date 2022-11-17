# frozen_string_literal: true

ActiveRecord::Type.register(:sym_jsonb, Gitlab::Database::Type::SymbolizedJsonb)
