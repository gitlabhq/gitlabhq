# frozen_string_literal: true
module Projects
  module GoogleCloud
    module CloudsqlHelper
      # Sources:
      # - https://cloud.google.com/sql/docs/postgres/instance-settings
      # - https://cloud.google.com/sql/docs/mysql/instance-settings
      # - https://cloud.google.com/sql/docs/sqlserver/instance-settings

      TIERS = [
        { value: 'db-custom-1-3840', label: '1 vCPU, 3840 MB RAM - Standard' },
        { value: 'db-custom-2-7680', label: '2 vCPU, 7680 MB RAM - Standard' },
        { value: 'db-custom-2-13312', label: '2 vCPU, 13312 MB RAM - High memory' },
        { value: 'db-custom-4-15360', label: '4 vCPU, 15360 MB RAM - Standard' },
        { value: 'db-custom-4-26624', label: '4 vCPU, 26624 MB RAM - High memory' },
        { value: 'db-custom-8-30720', label: '8 vCPU, 30720 MB RAM - Standard' },
        { value: 'db-custom-8-53248', label: '8 vCPU, 53248 MB RAM - High memory' },
        { value: 'db-custom-16-61440', label: '16 vCPU, 61440 MB RAM - Standard' },
        { value: 'db-custom-16-106496', label: '16 vCPU, 106496 MB RAM - High memory' },
        { value: 'db-custom-32-122880', label: '32 vCPU, 122880 MB RAM - Standard' },
        { value: 'db-custom-32-212992', label: '32 vCPU, 212992 MB RAM - High memory' },
        { value: 'db-custom-64-245760', label: '64 vCPU, 245760 MB RAM - Standard' },
        { value: 'db-custom-64-425984', label: '64 vCPU, 425984 MB RAM - High memory' },
        { value: 'db-custom-96-368640', label: '96 vCPU, 368640 MB RAM - Standard' },
        { value: 'db-custom-96-638976', label: '96 vCPU, 638976 MB RAM - High memory' }
      ].freeze

      VERSIONS = {
        postgres: [
          { value: 'POSTGRES_14', label: 'PostgreSQL 14' },
          { value: 'POSTGRES_13', label: 'PostgreSQL 13' },
          { value: 'POSTGRES_12', label: 'PostgreSQL 12' },
          { value: 'POSTGRES_11', label: 'PostgreSQL 11' },
          { value: 'POSTGRES_10', label: 'PostgreSQL 10' },
          { value: 'POSTGRES_9_6', label: 'PostgreSQL 9.6' }
        ],
        mysql: [
          { value: 'MYSQL_8_0', label: 'MySQL 8' },
          { value: 'MYSQL_5_7', label: 'MySQL 5.7' },
          { value: 'MYSQL_5_6', label: 'MySQL 5.6' }
        ],
        sqlserver: [
          { value: 'SQLSERVER_2017_STANDARD', label: 'SQL Server 2017 Standard' },
          { value: 'SQLSERVER_2017_ENTERPRISE', label: 'SQL Server 2017 Enterprise' },
          { value: 'SQLSERVER_2017_EXPRESS', label: 'SQL Server 2017 Express' },
          { value: 'SQLSERVER_2017_WEB', label: 'SQL Server 2017 Web' },
          { value: 'SQLSERVER_2019_STANDARD', label: 'SQL Server 2019 Standard' },
          { value: 'SQLSERVER_2019_ENTERPRISE', label: 'SQL Server 2019 Enterprise' },
          { value: 'SQLSERVER_2019_EXPRESS', label: 'SQL Server 2019 Express' },
          { value: 'SQLSERVER_2019_WEB', label: 'SQL Server 2019 Web' }
        ]
      }.freeze
    end
  end
end
