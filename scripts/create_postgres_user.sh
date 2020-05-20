#!/usr/bin/env bash

psql -h postgres -U postgres postgres <<EOF
CREATE USER gitlab;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO gitlab;
EOF
