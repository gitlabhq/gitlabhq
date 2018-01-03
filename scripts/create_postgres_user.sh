#!/bin/bash

psql -h postgres -U postgres postgres <<EOF
DROP DATABASE IF EXISTS gitlabhq_test;
CREATE DATABASE gitlabhq_test;
CREATE USER gitlab;
GRANT ALL PRIVILEGES ON DATABASE gitlabhq_test TO gitlab;
EOF
