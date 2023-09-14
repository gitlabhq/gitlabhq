CREATE TABLE sync_cursors
(
  table_name LowCardinality(String) DEFAULT '',
  primary_key_value UInt64 DEFAULT 0,
  recorded_at DateTime64(6, 'UTC') DEFAULT now()
)
ENGINE = ReplacingMergeTree(recorded_at)
ORDER BY (table_name)
PRIMARY KEY (table_name)
