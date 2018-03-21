#!/bin/bash

mysql --user=root --host=mysql <<EOF
CREATE DATABASE IF NOT EXISTS gitlabhq_test DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS 'gitlab'@'%';
GRANT ALL PRIVILEGES ON gitlabhq_test.* TO 'gitlab'@'%';
FLUSH PRIVILEGES;
EOF
