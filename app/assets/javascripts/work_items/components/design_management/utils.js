import { findDesignWidget } from '../../utils';

export const findVersionId = (id) => (id.match('::Version/(.+$)') || [])[1];

export const extractDesigns = (data) =>
  findDesignWidget(data.project.workItems.nodes[0].widgets).designCollection.designs.nodes;

export const extractDesign = (data) => (extractDesigns(data) || [])[0];

export const getPageLayoutElement = () => document.querySelector('.layout-page');
