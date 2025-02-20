import { IMPORT_HISTORY_TABLE_STATUS } from '~/vue_shared/components/import/constants';

const sixMonthsAgo = () => new Date(new Date().getTime() - 190 * 24 * 60 * 60 * 1000);
const oneMonthAgo = () => new Date(new Date().getTime() - 31 * 24 * 60 * 60 * 1000);
const fiveMinutesAgo = () => new Date(new Date().getTime() - 5 * 60 * 1000);
const inFiveHours = () => new Date(new Date().getTime() + 6 * 60 * 60 * 1000);

export const apiItems = [
  {
    id: 0,
    bulk_import_id: 0,
    status_name: IMPORT_HISTORY_TABLE_STATUS.unstarted,
    entity_type: 'project',
    source_full_path: 'https://github.com/name/project.git',
    full_path: 'my-group/project',
    destination_name: 'project',
    destination_slug: 'project',
    destination_namespace: 'my-group',
    parent_id: 0,
    namespace_id: 2,
    project_id: 0,
    created_at: inFiveHours(),
    migrate_projects: true,
    migrate_memberships: true,
    has_failures: false,
    stats: {
      labels: {
        source: 10,
        fetched: 10,
        imported: 0,
      },
      milestones: {
        source: 10,
        fetched: 10,
        imported: 0,
      },
    },
  },
  {
    id: 1,
    bulk_import_id: 1,
    status_name: IMPORT_HISTORY_TABLE_STATUS.inProgress,
    entity_type: 'group',
    source_full_path: 'https://another.gitlab.com/groupname',
    full_path: 'groupname',
    destination_name: 'groupname',
    destination_slug: 'groupname',
    destination_namespace: 'groupname',
    parent_id: 0,
    namespace_id: 2,
    project_id: 0,
    created_at: fiveMinutesAgo(),
    updated_at: fiveMinutesAgo(),
    failures: [
      {
        relation: 'design',
        exception_message: 'custom error message',
        exception_class: 'Exception',
        correlation_id_value: 'dfcf583058ed4508e4c7c617bd7f0edd',
        source_url: 'https://github.com/name/project.git',
        source_title: 'some title',
      },
    ],
    migrate_projects: true,
    migrate_memberships: true,
    has_failures: true,
    stats: {
      labels: {
        source: 10,
        fetched: 10,
        imported: 3,
      },
      milestones: {
        source: 10,
        fetched: 10,
        imported: 9,
      },
    },
    nestedRow: {
      id: 214,
      bulk_import_id: 0,
      status_name: IMPORT_HISTORY_TABLE_STATUS.inProgress,
      entity_type: 'project',
      source_full_path: 'https://another.gitlab.com/groupname/project.git',
      full_path: 'my-group/groupname/project',
      destination_name: 'project',
      destination_slug: 'project',
      destination_namespace: 'my-group/groupname',
      parent_id: 0,
      namespace_id: 2,
      project_id: 0,
      created_at: fiveMinutesAgo(),
      updated_at: fiveMinutesAgo(),
      failures: [
        {
          relation: 'design',
          exception_message: 'custom error message',
          exception_class: 'Exception',
          correlation_id_value: 'dfcf583058ed4508e4c7c617bd7f0edd',
          source_url: 'https://github.com/name/project.git',
          source_title: 'some title',
        },
      ],
      migrate_projects: true,
      migrate_memberships: true,
      has_failures: true,
      stats: {
        design: {
          source: 10,
          fetched: 10,
          imported: 3,
        },
      },
    },
  },
  // a project imported from a file
  {
    id: 2,
    bulk_import_id: 2,
    status_name: IMPORT_HISTORY_TABLE_STATUS.complete,
    entity_type: 'file',
    fileName: 'project2.gz',
    full_path: 'my-group/project2',
    destination_name: 'project2',
    destination_slug: 'project2',
    destination_namespace: 'my-group',
    parent_id: 0,
    namespace_id: 2,
    project_id: 0,
    created_at: oneMonthAgo(),
    updated_at: oneMonthAgo(),
    migrate_projects: true,
    migrate_memberships: true,
    has_failures: false,
    stats: {
      labels: {
        source: 1096,
        fetched: 1096,
        imported: 1096,
      },
      milestones: {
        source: 10,
        fetched: 10,
        imported: 10,
      },
      uploads: {
        source: 123,
        fetched: 123,
        imported: 123,
      },
    },
  },
  // A project imported from a file that errored out
  {
    id: 3,
    bulk_import_id: 3,
    status_name: IMPORT_HISTORY_TABLE_STATUS.failed,
    entity_type: 'file',
    fileName: 'project3.gz',
    full_path: 'my-group/project3',
    destination_name: 'project3',
    destination_slug: 'project3',
    destination_namespace: 'my-group',
    parent_id: 0,
    namespace_id: 2,
    project_id: 0,
    created_at: sixMonthsAgo(),
    updated_at: sixMonthsAgo(),
    migrate_projects: true,
    migrate_memberships: true,
    has_failures: true,
    stats: {},
    failures: [
      {
        relation: 'design',
        exception_message: `At this point, we don't know what's happened and how to fix it. But you can try to troubleshoot it with documentation.`,
        exception_class: 'Exception',
        correlation_id_value: 'dfcf583058ed4508e4c7c617bd7f0edd',
        source_url: 'https://github.com/name/project.git',
        source_title: 'some title',
        raw: `ENOENT: No such file or directory`,
        link_text: 'See documentation',
      },
    ],
  },
];

export const basic = {
  items: apiItems,
  // eslint-disable-next-line no-restricted-syntax
  detailsPath: 'http://docs.gitlab.com/ee/user/project/import/import_file.html',
};
