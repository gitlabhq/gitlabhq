import { range } from 'lodash';

export const TEST_NAV_DATA = {
  activeTitle: 'Test Active Title',
  primary: [
    ...['projects', 'groups'].map((view) => ({
      id: view,
      href: null,
      title: view,
      view,
    })),
    ...range(0, 2).map((idx) => ({
      id: `primary-link-${idx}`,
      href: `/path/to/primary/${idx}`,
      title: `Title ${idx}`,
    })),
  ],
  secondary: range(0, 2).map((idx) => ({
    id: `secondary-link-${idx}`,
    href: `/path/to/secondary/${idx}`,
    title: `SecTitle ${idx}`,
  })),
  views: {
    projects: {
      namespace: 'projects',
      currentUserName: '',
      currentItem: {},
      linksPrimary: [{ id: 'project-link', href: '/path/to/projects', title: 'Project Link' }],
      linksSecondary: [],
    },
    groups: {
      namespace: 'groups',
      currentUserName: '',
      currentItem: {},
      linksPrimary: [],
      linksSecondary: [{ id: 'group-link', href: '/path/to/groups', title: 'Group Link' }],
    },
  },
};
