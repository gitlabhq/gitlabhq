CREATE TABLE events
(
  id UInt64 DEFAULT 0,
  path String DEFAULT '',
  author_id UInt64 DEFAULT 0,
  target_id UInt64 DEFAULT 0,
  target_type LowCardinality(String) DEFAULT '',
  action UInt8 DEFAULT 0,
  created_at DateTime64(6, 'UTC') DEFAULT now(),
  updated_at DateTime64(6, 'UTC') DEFAULT now()
)
ENGINE = ReplacingMergeTree(updated_at)
PRIMARY KEY (id)
ORDER BY (id)
PARTITION BY toYear(created_at)
