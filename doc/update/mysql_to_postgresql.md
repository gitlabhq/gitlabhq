# Use the shell commands below to convert a MySQL GitLab database to a PostgreSQL one.

```
git clone https://github.com/lanyrd/mysql-postgresql-converter.git
cd mysql-postgresql-converter
mysqldump --compatible=postgresql --default-character-set=utf8 -r databasename.mysql -u root gitlabhq_production
python db_converter.py databasename.mysql databasename.psql
psql -f databasename.psql -d gitlabhq_production
```
