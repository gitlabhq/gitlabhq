import {
  unwrapArrayOfJobs,
  unwrapGroups,
  unwrapNodesWithName,
  unwrapStagesWithNeeds,
} from '~/pipelines/components/unwrapping_utils';

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

const completeMock = [
  {
    ...basicStageInfo,
    groups: {
      nodes: groupsArray.map((group) => ({ ...group, jobs: { nodes: jobArrayWithNeeds } })),
    },
  },
];

describe('Shared pipeline unwrapping utils', () => {
  describe('unwrapArrayOfJobs', () => {
    it('returns an empty array if the input is an empty undefined', () => {
      expect(unwrapArrayOfJobs(undefined)).toEqual([]);
    });

    it('returns an empty array if the input is an empty array', () => {
      expect(unwrapArrayOfJobs([])).toEqual([]);
    });

    it('returns a flatten array of each job with their data and stage name', () => {
      expect(
        unwrapArrayOfJobs([
          { name: 'build', groups: [{ name: 'job_a_1' }, { name: 'job_a_2' }] },
          { name: 'test', groups: [{ name: 'job_b' }] },
        ]),
      ).toMatchObject([
        { category: 'build', name: 'job_a_1' },
        { category: 'build', name: 'job_a_2' },
        { category: 'test', name: 'job_b' },
      ]);
    });
  });

  describe('unwrapGroups', () => {
    it('takes stages without nodes and returns the unwrapped groups', () => {
      expect(unwrapGroups(stagesAndGroups)[0].groups).toEqual(groupsArray);
    });

    it('keeps other stage properties intact', () => {
      expect(unwrapGroups(stagesAndGroups)[0]).toMatchObject(basicStageInfo);
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

  describe('unwrapStagesWithNeeds', () => {
    it('removes nodes from groups, jobs, and needs', () => {
      const firstProcessedGroup = unwrapStagesWithNeeds(completeMock)[0].groups[0];
      expect(firstProcessedGroup).toMatchObject(groupsArray[0]);
      expect(firstProcessedGroup.jobs[0]).toMatchObject(baseJobs);
      expect(firstProcessedGroup.jobs[0].needs[0]).toBe(needArray[0].name);
    });
  });
});
