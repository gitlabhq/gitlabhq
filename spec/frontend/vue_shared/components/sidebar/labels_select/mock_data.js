export const mockLabels = [
  {
    id: 26,
    title: 'Foo Label',
    description: 'Foobar',
    color: '#BADA55',
    text_color: '#FFFFFF',
  },
  {
    id: 27,
    title: 'Foo::Bar',
    description: 'Foobar',
    color: '#0033CC',
    text_color: '#FFFFFF',
  },
];

export const mockSuggestedColors = {
  '#0033CC': 'UA blue',
  '#428BCA': 'Moderate blue',
  '#44AD8E': 'Lime green',
  '#A8D695': 'Feijoa',
  '#5CB85C': 'Slightly desaturated green',
  '#69D100': 'Bright green',
  '#004E00': 'Very dark lime green',
  '#34495E': 'Very dark desaturated blue',
  '#7F8C8D': 'Dark grayish cyan',
  '#A295D6': 'Slightly desaturated blue',
  '#5843AD': 'Dark moderate blue',
  '#8E44AD': 'Dark moderate violet',
  '#FFECDB': 'Very pale orange',
  '#AD4363': 'Dark moderate pink',
  '#D10069': 'Strong pink',
  '#CC0033': 'Strong red',
  '#FF0000': 'Pure red',
  '#D9534F': 'Soft red',
  '#D1D100': 'Strong yellow',
  '#F0AD4E': 'Soft orange',
  '#AD8D43': 'Dark moderate orange',
};

export const mockConfig = {
  showCreate: true,
  isProject: true,
  abilityName: 'issue',
  context: {
    labels: mockLabels,
  },
  namespace: 'gitlab-org',
  updatePath: '/gitlab-org/my-project/issue/1',
  labelsPath: '/gitlab-org/my-project/-/labels.json',
  labelsWebUrl: '/gitlab-org/my-project/-/labels',
  labelFilterBasePath: '/gitlab-org/my-project/issues',
  canEdit: true,
  suggestedColors: mockSuggestedColors,
  emptyValueText: 'None',
};
