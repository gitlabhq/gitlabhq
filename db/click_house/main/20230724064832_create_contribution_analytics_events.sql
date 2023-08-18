CREATE TABLE contribution_analytics_events
(
    id UInt64 DEFAULT 0,
    path String DEFAULT '',
    author_id UInt64 DEFAULT 0,
    target_type LowCardinality(String) DEFAULT '',
    action UInt8 DEFAULT 0,
    created_at Date DEFAULT toDate(now()),
    updated_at DateTime64(6, 'UTC') DEFAULT now()
)
    ENGINE = MergeTree
    ORDER BY (path, created_at, author_id, id)
    PARTITION BY toYear(created_at);
