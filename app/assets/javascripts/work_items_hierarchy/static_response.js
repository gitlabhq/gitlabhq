const FREE_TIER = 'free';
const ULTIMATE_TIER = 'ultimate';
const PREMIUM_TIER = 'premium';

const RESPONSE = {
  [FREE_TIER]: [
    {
      id: '1',
      type: 'ISSUE',
      available: true,
      license: null,
      nestedTypes: null,
    },
    {
      id: '2',
      type: 'TASK',
      available: true,
      license: null,
      nestedTypes: null,
    },
    {
      id: '3',
      type: 'INCIDENT',
      available: true,
      license: null,
      nestedTypes: null,
    },
    {
      id: '4',
      type: 'EPIC',
      available: false,
      license: 'Premium', // eslint-disable-line @gitlab/require-i18n-strings
      nestedTypes: null,
    },
    {
      id: '5',
      type: 'SUB_EPIC',
      available: false,
      license: 'Ultimate', // eslint-disable-line @gitlab/require-i18n-strings
      nestedTypes: null,
    },
    {
      id: '6',
      type: 'REQUIREMENT',
      available: false,
      license: 'Ultimate', // eslint-disable-line @gitlab/require-i18n-strings
      nestedTypes: null,
    },
    {
      id: '7',
      type: 'TEST_CASE',
      available: false,
      license: 'Ultimate', // eslint-disable-line @gitlab/require-i18n-strings
      nestedTypes: null,
    },
  ],

  [PREMIUM_TIER]: [
    {
      id: '1',
      type: 'EPIC',
      available: true,
      license: null,
      nestedTypes: ['ISSUE'],
    },
    {
      id: '2',
      type: 'TASK',
      available: true,
      license: null,
      nestedTypes: null,
    },
    {
      id: '3',
      type: 'INCIDENT',
      available: true,
      license: null,
      nestedTypes: null,
    },
    {
      id: '5',
      type: 'SUB_EPIC',
      available: false,
      license: 'Ultimate', // eslint-disable-line @gitlab/require-i18n-strings
      nestedTypes: null,
    },
    {
      id: '6',
      type: 'REQUIREMENT',
      available: false,
      license: 'Ultimate', // eslint-disable-line @gitlab/require-i18n-strings
      nestedTypes: null,
    },
    {
      id: '7',
      type: 'TEST_CASE',
      available: false,
      license: 'Ultimate', // eslint-disable-line @gitlab/require-i18n-strings
      nestedTypes: null,
    },
  ],

  [ULTIMATE_TIER]: [
    {
      id: '1',
      type: 'EPIC',
      available: true,
      license: null,
      nestedTypes: ['SUB_EPIC', 'ISSUE'],
    },
    {
      id: '2',
      type: 'TASK',
      available: true,
      license: null,
      nestedTypes: null,
    },
    {
      id: '3',
      type: 'INCIDENT',
      available: true,
      license: null,
      nestedTypes: null,
    },
    {
      id: '6',
      type: 'REQUIREMENT',
      available: true,
      license: null,
      nestedTypes: null,
    },
    {
      id: '7',
      type: 'TEST_CASE',
      available: true,
      license: null,
      nestedTypes: null,
    },
  ],
};

export default RESPONSE;
