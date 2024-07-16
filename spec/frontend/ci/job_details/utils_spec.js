import { compactJobLog, filterAnnotations } from '~/ci/job_details/utils';
import { mockJobLog } from 'jest/ci/jobs_mock_data';

describe('Job utils', () => {
  describe('compactJobLog', () => {
    it('compacts job log correctly', () => {
      const expectedResults = [
        {
          content: [
            {
              text: 'Running with gitlab-runner 15.0.0 (febb2a09)',
            },
          ],
          lineNumber: 0,
          offset: 0,
        },
        {
          content: [
            {
              text: '  on colima-docker EwM9WzgD',
            },
          ],
          lineNumber: 1,
          offset: 54,
        },
        {
          content: [
            {
              style: 'term-fg-l-cyan term-bold',
              text: 'Resolving secrets',
            },
          ],
          lineNumber: 2,
          offset: 91,
          section: 'resolve-secrets',
          section_duration: '00:00',
          section_header: true,
        },
        {
          content: [
            {
              style: 'term-fg-l-cyan term-bold',
              text: 'Preparing the "docker" executor',
            },
          ],
          lineNumber: 4,
          offset: 218,
          section: 'prepare-executor',
          section_duration: '00:01',
          section_header: true,
        },
        {
          content: [
            {
              text: 'Using Docker executor with image ruby:2.7 ...',
            },
          ],
          lineNumber: 5,
          offset: 317,
          section: 'prepare-executor',
        },
        {
          content: [
            {
              text: 'Pulling docker image ruby:2.7 ...',
            },
          ],
          lineNumber: 6,
          offset: 372,
          section: 'prepare-executor',
        },
        {
          content: [
            {
              text: 'Using docker image sha256:55106bf6ba7f452c38d01ea760affc6ceb67d4b60068ffadab98d1b7b007668c for ruby:2.7 with digest ruby@sha256:23d08a4bae1a12ee3fce017f83204fcf9a02243443e4a516e65e5ff73810a449 ...',
            },
          ],
          lineNumber: 7,
          offset: 415,
          section: 'prepare-executor',
        },
        {
          content: [
            {
              style: 'term-fg-l-cyan term-bold',
              text: 'Preparing environment',
            },
          ],
          lineNumber: 9,
          offset: 665,
          section: 'prepare-script',
          section_duration: '00:01',
          section_header: true,
        },
        {
          content: [
            {
              text: 'Running on runner-ewm9wzgd-project-20-concurrent-0 via 8ea689ec6969...',
            },
          ],
          lineNumber: 10,
          offset: 752,
          section: 'prepare-script',
        },
        {
          content: [
            {
              style: 'term-fg-l-cyan term-bold',
              text: 'Getting source from Git repository',
            },
          ],
          lineNumber: 12,
          offset: 865,
          section: 'get-sources',
          section_duration: '00:01',
          section_header: true,
        },
        {
          content: [
            {
              style: 'term-fg-l-green term-bold',
              text: 'Fetching changes with git depth set to 20...',
            },
          ],
          lineNumber: 13,
          offset: 962,
          section: 'get-sources',
        },
        {
          content: [
            {
              text: 'Reinitialized existing Git repository in /builds/root/ci-project/.git/',
            },
          ],
          lineNumber: 14,
          offset: 1019,
          section: 'get-sources',
        },
        {
          content: [
            {
              style: 'term-fg-l-green term-bold',
              text: 'Checking out e0f63d76 as main...',
            },
          ],
          lineNumber: 15,
          offset: 1090,
          section: 'get-sources',
        },
        {
          content: [
            {
              style: 'term-fg-l-green term-bold',
              text: 'Skipping Git submodules setup',
            },
          ],
          lineNumber: 16,
          offset: 1136,
          section: 'get-sources',
        },
        {
          content: [
            {
              style: 'term-fg-l-cyan term-bold',
              text: 'Executing "step_script" stage of the job script',
            },
          ],
          lineNumber: 18,
          offset: 1217,
          section: 'step-script',
          section_duration: '00:00',
          section_header: true,
        },
        {
          content: [
            {
              text: 'Using docker image sha256:55106bf6ba7f452c38d01ea760affc6ceb67d4b60068ffadab98d1b7b007668c for ruby:2.7 with digest ruby@sha256:23d08a4bae1a12ee3fce017f83204fcf9a02243443e4a516e65e5ff73810a449 ...',
            },
          ],
          lineNumber: 19,
          offset: 1327,
          section: 'step-script',
        },
        {
          content: [
            {
              style: 'term-fg-l-green term-bold',
              text: '$ echo "82.71"',
            },
          ],
          lineNumber: 20,
          offset: 1533,
          section: 'step-script',
        },
        {
          content: [
            {
              text: '82.71',
            },
          ],
          lineNumber: 21,
          offset: 1560,
          section: 'step-script',
        },
        {
          content: [
            {
              style: 'term-fg-l-green term-bold',
              text: 'Job succeeded',
            },
          ],
          lineNumber: 23,
          offset: 1605,
        },
      ];

      expect(compactJobLog(mockJobLog)).toStrictEqual(expectedResults);
    });
  });

  describe('filterAnnotations', () => {
    it('filters annotations by type', () => {
      const data = [
        {
          name: 'b',
          data: [
            {
              dummy: {},
            },
            {
              external_link: {
                label: 'URL 2',
                url: 'https://url2.example.com/',
              },
            },
          ],
        },
        {
          name: 'a',
          data: [
            {
              external_link: {
                label: 'URL 1',
                url: 'https://url1.example.com/',
              },
            },
          ],
        },
      ];

      expect(filterAnnotations(data, 'external_link')).toEqual([
        {
          label: 'URL 1',
          url: 'https://url1.example.com/',
        },
        {
          label: 'URL 2',
          url: 'https://url2.example.com/',
        },
      ]);
    });
  });
});
