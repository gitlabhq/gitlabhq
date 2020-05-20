#!/usr/bin/env bash

psql -h postgres -U postgres gitlabhq_geo_test <<EOF
CREATE EXTENSION postgres_fdw;
CREATE SERVER gitlab_secondary FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'localhost', dbname 'gitlabhq_test');
CREATE USER MAPPING FOR current_user SERVER gitlab_secondary OPTIONS (user 'postgres', password '');
CREATE SCHEMA gitlab_secondary;
IMPORT FOREIGN SCHEMA public FROM SERVER gitlab_secondary INTO gitlab_secondary;
GRANT USAGE ON FOREIGN SERVER gitlab_secondary TO current_user;
EOF

# Ensure the FDW setting is enabled
sed -i '/fdw:/d' config/database_geo.yml
sed -i '/gitlabhq_geo_test/a\
\ \ fdw: true' config/database_geo.yml
