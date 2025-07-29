import isEmpty from 'lodash/isEmpty';

export const isEmptyPanelData = (visualizationType, data) => {
  if (visualizationType === 'SingleStat') {
    // SingleStat visualizations currently do not show an empty state, and instead show a default "0" value
    // This will be revisited: https://gitlab.com/gitlab-org/gitlab/-/issues/398792
    return false;
  }
  return isEmpty(data);
};

const filterUndefinedValues = (obj) => {
  // eslint-disable-next-line no-unused-vars
  return Object.fromEntries(Object.entries(obj).filter(([_, value]) => value !== undefined));
};

/**
 * Parses a dashboard panel config into a GridStack item.
 */
export const parsePanelToGridItem = ({
  gridAttributes: { xPos, yPos, width, height, minHeight, minWidth, maxHeight, maxWidth },
  id,
  ...rest
}) =>
  // GridStack renders undefined layout values so we need to filter them out.
  filterUndefinedValues({
    x: xPos,
    y: yPos,
    w: width,
    h: height,
    minH: minHeight,
    minW: minWidth,
    maxH: maxHeight,
    maxW: maxWidth,
    id,
    props: {
      id,
      ...rest,
    },
  });

export const dashboardConfigValidator = (config) => {
  if (config.panels) {
    if (!Array.isArray(config.panels)) return false;
    if (!config.panels.every((panel) => panel.id && panel.gridAttributes)) return false;
  }

  return true;
};
