import { shallowMount } from '@vue/test-utils';
import { setHTMLFixture } from 'helpers/fixtures';
import LinksInner from '~/pipelines/components/graph_shared/links_inner.vue';
import { parseData } from '~/pipelines/components/parsing_utils';
import { createJobsHash } from '~/pipelines/utils';
import {
  jobRect,
  largePipelineData,
  parallelNeedData,
  pipelineData,
  pipelineDataWithNoNeeds,
  rootRect,
  sameStageNeeds,
} from '../pipeline_graph/mock_data';

describe('Links Inner component', () => {
  const containerId = 'pipeline-graph-container';
  const defaultProps = {
    containerId,
    containerMeasurements: { width: 1019, height: 445 },
    pipelineId: 1,
    pipelineData: [],
    totalGroups: 10,
  };

  let wrapper;

  const createComponent = (props) => {
    const currentPipelineData = props?.pipelineData || defaultProps.pipelineData;
    wrapper = shallowMount(LinksInner, {
      propsData: {
        ...defaultProps,
        ...props,
        parsedData: parseData(currentPipelineData.flatMap(({ groups }) => groups)),
      },
    });
  };

  const findLinkSvg = () => wrapper.find('#link-svg');
  const findAllLinksPath = () => findLinkSvg().findAll('path');

  // We create fixture so that each job has an empty div that represent
  // the JobPill in the DOM. Each `JobPill` would have different coordinates,
  // so we increment their coordinates on each iteration to simulate different positions.
  const setFixtures = ({ stages }) => {
    const jobs = createJobsHash(stages);
    const arrayOfJobs = Object.keys(jobs);

    const linksHtmlElements = arrayOfJobs.map((job) => {
      return `<div id=${job}-${defaultProps.pipelineId} />`;
    });

    setHTMLFixture(`<div id="${containerId}">${linksHtmlElements.join(' ')}</div>`);

    // We are mocking the clientRect data of each job and the container ID.
    jest
      .spyOn(document.getElementById(containerId), 'getBoundingClientRect')
      .mockImplementation(() => rootRect);

    arrayOfJobs.forEach((job, index) => {
      jest
        .spyOn(
          document.getElementById(`${job}-${defaultProps.pipelineId}`),
          'getBoundingClientRect',
        )
        .mockImplementation(() => {
          const newValue = 10 * index;
          const { left, right, top, bottom, x, y } = jobRect;
          return {
            ...jobRect,
            left: left + newValue,
            right: right + newValue,
            top: top + newValue,
            bottom: bottom + newValue,
            x: x + newValue,
            y: y + newValue,
          };
        });
    });
  };

  afterEach(() => {
    jest.restoreAllMocks();
    wrapper.destroy();
  });

  describe('basic SVG creation', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders an SVG of the right size', () => {
      expect(findLinkSvg().exists()).toBe(true);
      expect(findLinkSvg().attributes('width')).toBe(
        `${defaultProps.containerMeasurements.width}px`,
      );
      expect(findLinkSvg().attributes('height')).toBe(
        `${defaultProps.containerMeasurements.height}px`,
      );
    });
  });

  describe('no pipeline data', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the component', () => {
      expect(findLinkSvg().exists()).toBe(true);
      expect(findAllLinksPath()).toHaveLength(0);
    });
  });

  describe('pipeline data with no needs', () => {
    beforeEach(() => {
      createComponent({ pipelineData: pipelineDataWithNoNeeds.stages });
    });

    it('renders no links', () => {
      expect(findLinkSvg().exists()).toBe(true);
      expect(findAllLinksPath()).toHaveLength(0);
    });
  });

  describe('with one need', () => {
    beforeEach(() => {
      setFixtures(pipelineData);
      createComponent({ pipelineData: pipelineData.stages });
    });

    it('renders one link', () => {
      expect(findAllLinksPath()).toHaveLength(1);
    });

    it('path does not contain NaN values', () => {
      expect(wrapper.html()).not.toContain('NaN');
    });

    it('matches snapshot and has expected path', () => {
      expect(wrapper.html()).toMatchSnapshot();
    });
  });

  describe('with a parallel need', () => {
    beforeEach(() => {
      setFixtures(parallelNeedData);
      createComponent({ pipelineData: parallelNeedData.stages });
    });

    it('renders only one link for all the same parallel jobs', () => {
      expect(findAllLinksPath()).toHaveLength(1);
    });

    it('path does not contain NaN values', () => {
      expect(wrapper.html()).not.toContain('NaN');
    });

    it('matches snapshot and has expected path', () => {
      expect(wrapper.html()).toMatchSnapshot();
    });
  });

  describe('with same stage needs', () => {
    beforeEach(() => {
      setFixtures(sameStageNeeds);
      createComponent({ pipelineData: sameStageNeeds.stages });
    });

    it('renders the correct number of links', () => {
      expect(findAllLinksPath()).toHaveLength(2);
    });

    it('path does not contain NaN values', () => {
      expect(wrapper.html()).not.toContain('NaN');
    });

    it('matches snapshot and has expected path', () => {
      expect(wrapper.html()).toMatchSnapshot();
    });
  });

  describe('with a large number of needs', () => {
    beforeEach(() => {
      setFixtures(largePipelineData);
      createComponent({ pipelineData: largePipelineData.stages });
    });

    it('renders the correct number of links', () => {
      expect(findAllLinksPath()).toHaveLength(5);
    });

    it('path does not contain NaN values', () => {
      expect(wrapper.html()).not.toContain('NaN');
    });

    it('matches snapshot and has expected path', () => {
      expect(wrapper.html()).toMatchSnapshot();
    });
  });

  describe('interactions', () => {
    beforeEach(() => {
      setFixtures(largePipelineData);
      createComponent({ pipelineData: largePipelineData.stages });
    });

    it('highlight needs on hover', async () => {
      const firstLink = findAllLinksPath().at(0);

      const defaultColorClass = 'gl-stroke-gray-200';
      const hoverColorClass = 'gl-stroke-blue-400';

      expect(firstLink.classes(defaultColorClass)).toBe(true);
      expect(firstLink.classes(hoverColorClass)).toBe(false);

      // Because there is a watcher, we need to set the props after the component
      // has mounted.
      await wrapper.setProps({ highlightedJob: 'test_1' });

      expect(firstLink.classes(defaultColorClass)).toBe(false);
      expect(firstLink.classes(hoverColorClass)).toBe(true);
    });
  });
});
