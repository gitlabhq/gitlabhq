export const dashboard = {
  id: 'analytics_overview',
  slug: 'analytics_overview',
  title: 'Analytics Overview',
  description: 'This is a dashboard',
  userDefined: true,
  panels: [
    {
      title: 'Test A',
      gridAttributes: { width: 3, height: 3 },
      id: 'panel-A',
    },
    {
      title: 'Test B',
      gridAttributes: { width: 2, height: 4, minHeight: 2, minWidth: 2 },
      id: 'panel-B',
    },
  ],
  status: null,
  errors: null,
};

export const mockPanel = {
  title: 'Test C',
  gridAttributes: {
    width: 2,
    height: 4,
    minHeight: 2,
    minWidth: 2,
    xPos: 6,
    yPos: 2,
    maxWidth: 4,
    maxHeight: 4,
  },
  id: 'panel-C',
};
