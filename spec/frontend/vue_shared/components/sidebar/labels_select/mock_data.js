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
  '#009966': 'Green-cyan',
  '#8fbc8f': 'Dark sea green',
  '#3cb371': 'Medium sea green',
  '#00b140': 'Green screen',
  '#013220': 'Dark green',
  '#6699cc': 'Blue-gray',
  '#0000ff': 'Blue',
  '#e6e6fa': 'Lavendar',
  '#9400d3': 'Dark violet',
  '#330066': 'Deep violet',
  '#808080': 'Gray',
  '#36454f': 'Charcoal grey',
  '#f7e7ce': 'Champagne',
  '#c21e56': 'Rose red',
  '#cc338b': 'Magenta-pink',
  '#dc143c': 'Crimson',
  '#ff0000': 'Red',
  '#cd5b45': 'Dark coral',
  '#eee600': 'Titanium yellow',
  '#ed9121': 'Carrot orange',
  '#c39953': 'Aztec Gold',
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
