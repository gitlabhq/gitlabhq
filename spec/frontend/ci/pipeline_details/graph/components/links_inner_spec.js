import { shallowMount } from '@vue/test-utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import LinksInner from '~/ci/pipeline_details/graph/components/links_inner.vue';
import { parseData } from '~/ci/pipeline_details/utils/parsing_utils';
import { createJobsHash } from '~/ci/pipeline_details/utils';
import {
  jobRect,
  largePipelineData,
  parallelNeedData,
  pipelineData,
  pipelineDataWithNoNeeds,
  rootRect,
  sameStageNeeds,
} from 'jest/ci/pipeline_editor/components/graph/mock_data';

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
        linksData: parseData(currentPipelineData.flatMap(({ groups }) => groups)).links,
      },
    });
  };

  const findLinkSvg = () => wrapper.find('#link-svg');
  const findAllLinksPath = () => findLinkSvg().findAll('path');

  const createJobId = (jobName, pipelineId) => `${jobName.replace(/[\s/]/g, '_')}-${pipelineId}`;

  const setHTMLFixtureLocal = ({ stages }) => {
    const POSITION_OFFSET = 10; // Pixel offset between each job element
    const jobs = Object.keys(createJobsHash(stages));

    // Create HTML elements and set fixture in one go
    setHTMLFixture(
      `<div id="${containerId}">${jobs
        .map((job) => `<div id=${createJobId(job, defaultProps.pipelineId)} />`)
        .join(' ')}
      </div>`,
    );

    // Mock container position
    jest
      .spyOn(document.getElementById(containerId), 'getBoundingClientRect')
      .mockImplementation(() => rootRect);

    // Mock job positions
    jobs.forEach((job, index) => {
      const element = document.getElementById(createJobId(job, defaultProps.pipelineId));
      if (!element) {
        throw new Error(`Job element ${job} not found after setting fixture`);
      }

      jest.spyOn(element, 'getBoundingClientRect').mockImplementation(() => ({
        ...jobRect,
        left: jobRect.left + index * POSITION_OFFSET,
        right: jobRect.right + index * POSITION_OFFSET,
        top: jobRect.top + index * POSITION_OFFSET,
        bottom: jobRect.bottom + index * POSITION_OFFSET,
        x: jobRect.x + index * POSITION_OFFSET,
        y: jobRect.y + index * POSITION_OFFSET,
      }));
    });
  };

  const setupComponentWithFixture = (data) => {
    setHTMLFixtureLocal(data);
    createComponent({ pipelineData: data.stages });
  };

  afterEach(() => {
    resetHTMLFixture();
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
      setupComponentWithFixture(pipelineData);
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
      setupComponentWithFixture(parallelNeedData);
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
      setupComponentWithFixture(sameStageNeeds);
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
      setupComponentWithFixture(largePipelineData);
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
      setupComponentWithFixture(largePipelineData);
    });

    it('highlight needs on hover', async () => {
      const firstLink = findAllLinksPath().at(0);

      const defaultColorClass = 'gl-stroke-gray-200';
      const hoverColorClass = 'gl-stroke-blue-400';

      expect(firstLink.classes(defaultColorClass)).toBe(true);
      expect(firstLink.classes(hoverColorClass)).toBe(false);

      await wrapper.setProps({ highlightedJob: 'test_1' });

      expect(firstLink.classes(defaultColorClass)).toBe(false);
      expect(firstLink.classes(hoverColorClass)).toBe(true);
    });
  });
});
