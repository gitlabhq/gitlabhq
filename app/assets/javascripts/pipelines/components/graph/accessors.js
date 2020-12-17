import { get } from 'lodash';
import { REST, GRAPHQL } from './constants';

const accessors = {
  [REST]: {
    detailsPath: 'details_path',
    groupId: 'id',
    hasDetails: 'has_details',
    pipelineStatus: ['details', 'status'],
    sourceJob: ['source_job', 'name'],
  },
  [GRAPHQL]: {
    detailsPath: 'detailsPath',
    groupId: 'name',
    hasDetails: 'hasDetails',
    pipelineStatus: 'status',
    sourceJob: ['sourceJob', 'name'],
  },
};

const accessValue = (dataMethod, prop, item) => {
  return get(item, accessors[dataMethod][prop]);
};

export { accessors, accessValue };
