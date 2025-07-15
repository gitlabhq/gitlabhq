import { unwrapGroups, unwrapNodesWithName } from '~/ci/pipeline_details/utils/unwrapping_utils';

const groupsArray = [
  {
    name: 'build_a',
    size: 1,
    status: {
      label: 'passed',
      group: 'success',
      icon: 'status_success',
    },
  },
  {
    name: 'bob_the_build',
    size: 1,
    status: {
      label: 'passed',
      group: 'success',
      icon: 'status_success',
    },
  },
];

const basicStageInfo = {
  name: 'center_stage',
  status: {
    action: null,
  },
};

const stagesAndGroups = [
  {
    ...basicStageInfo,
    groups: {
      nodes: groupsArray,
    },
  },
];

const needArray = [
  {
    name: 'build_b',
  },
];

const elephantArray = [
  {
    name: 'build_b',
    elephant: 'gray',
  },
];

const baseJobs = {
  name: 'test_d',
  status: {
    icon: 'status_success',
    tooltip: null,
    hasDetails: true,
    detailsPath: '/root/abcd-dag/-/pipelines/162',
    group: 'success',
    action: null,
  },
};

const jobArrayWithNeeds = [
  {
    ...baseJobs,
    needs: {
      nodes: needArray,
    },
  },
];

const jobArrayWithElephant = [
  {
    ...baseJobs,
    needs: {
      nodes: elephantArray,
    },
  },
];

describe('Shared pipeline unwrapping utils', () => {
  describe('unwrapGroups', () => {
    it('takes stages without nodes and returns the unwrapped groups', () => {
      expect(unwrapGroups(stagesAndGroups)[0].node.groups).toEqual(groupsArray);
    });

    it('keeps other stage properties intact', () => {
      expect(unwrapGroups(stagesAndGroups)[0].node).toMatchObject(basicStageInfo);
    });
  });

  describe('unwrapNodesWithName', () => {
    it('works with no field argument', () => {
      expect(unwrapNodesWithName(jobArrayWithNeeds, 'needs')[0].needs).toEqual([needArray[0].name]);
    });

    it('works with custom field argument', () => {
      expect(unwrapNodesWithName(jobArrayWithElephant, 'needs', 'elephant')[0].needs).toEqual([
        elephantArray[0].elephant,
      ]);
    });
  });
});
