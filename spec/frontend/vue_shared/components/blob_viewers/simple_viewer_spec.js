import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import {
  HIGHLIGHT_CLASS_NAME,
  MAX_BLAME_LINES,
} from '~/vue_shared/components/blob_viewers/constants';
import SimpleViewer from '~/vue_shared/components/blob_viewers/simple_viewer.vue';
import waitForPromises from 'helpers/wait_for_promises';

import blameDataQuery from '~/vue_shared/components/source_viewer/queries/blame_data.query.graphql';
import Blame from '~/vue_shared/components/source_viewer/components/blame_info.vue';

import { BLAME_DATA_QUERY_RESPONSE_MOCK } from './mock_data';

Vue.use(VueApollo);

describe('Blob Simple Viewer component', () => {
  let wrapper;
  let fakeApollo;
  const contentMock = `<span id="LC1">First</span>\n<span id="LC2">Second</span>\n<span id="LC3">Third</span>`;
  const blobHash = 'foo-bar';

  const blameDataQueryHandlerSuccess = jest.fn().mockResolvedValue(BLAME_DATA_QUERY_RESPONSE_MOCK);

  function createComponent({
    content = contentMock,
    showBlame = false,
    blamePath = '/blame/foo-bar',
    isBlameLinkHidden = false,
    isRawContent = false,
    propsData = {},
    glFeatures = {},
  } = {}) {
    fakeApollo = createMockApollo([[blameDataQuery, blameDataQueryHandlerSuccess]]);

    wrapper = shallowMount(SimpleViewer, {
      apolloProvider: fakeApollo,
      provide: {
        blobHash,
        glFeatures,
      },
      propsData: {
        content,
        type: 'text',
        fileName: 'test.js',
        isRawContent,
        isBlameLinkHidden,
        blamePath,
        blobPath: 'podfile',
        projectPath: 'test',
        currentRef: 'test',
        lineNumbers: 3,
        showBlame,
        ...propsData,
      },
    });
  }
  const findBlameComponents = () => wrapper.findAllComponents(Blame);
  const findBlameLinks = () => wrapper.findAll('.file-line-blame');

  it('does not fail if content is empty', () => {
    const spy = jest.spyOn(window.console, 'error');
    createComponent({ content: '' });
    expect(spy).not.toHaveBeenCalled();
  });

  describe('rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders exactly three lines', () => {
      expect(wrapper.findAll('.file-line-num')).toHaveLength(3);
    });

    it('renders a blame link for each line with correct href attribute', () => {
      expect(findBlameLinks()).toHaveLength(3);
      expect(findBlameLinks().at(0).attributes('href')).toBe('/blame/foo-bar#L1');
    });

    it('does not render blame link when `isBlameLinkHidden` prop set to true', () => {
      createComponent({ isBlameLinkHidden: true });
      expect(findBlameLinks()).toHaveLength(0);
    });

    it('renders the content without transformations', () => {
      expect(wrapper.html()).toContain(contentMock);
    });

    it('does not render a Blame component when `showBlame: false`', async () => {
      await waitForPromises();
      expect(findBlameComponents()).toHaveLength(0);
    });

    describe('Blame component', () => {
      beforeEach(() => {
        createComponent({ propsData: { showBlame: true } });
      });
      it('renders a Blame component with correct props', async () => {
        await waitForPromises();
        const blameInfo =
          BLAME_DATA_QUERY_RESPONSE_MOCK.data.project.repository.blobs.nodes[0].blame.groups;

        expect(findBlameComponents().at(0).exists()).toBe(true);
        expect(findBlameComponents().at(0).props()).toMatchObject({ blameInfo });
      });

      it('calls the blame data query', async () => {
        await waitForPromises();
        expect(blameDataQueryHandlerSuccess).toHaveBeenCalledTimes(1);
        expect(blameDataQueryHandlerSuccess).toHaveBeenCalledWith(
          expect.objectContaining({
            filePath: 'podfile',
            fromLine: 1,
            fullPath: 'test',
            ref: 'test',
            toLine: MAX_BLAME_LINES,
          }),
        );
      });

      it('if there is more than 100 lines it calls query as many time as needed', async () => {
        createComponent({ propsData: { showBlame: true, lineNumbers: 201 } });
        await waitForPromises();
        await waitForPromises();
        expect(blameDataQueryHandlerSuccess).toHaveBeenCalledTimes(4);
      });
    });
  });

  describe('functionality', () => {
    const scrollIntoViewMock = jest.fn();
    HTMLElement.prototype.scrollIntoView = scrollIntoViewMock;

    beforeEach(() => {
      window.location.hash = '#LC2';
      createComponent();
    });

    afterEach(() => {
      window.location.hash = '';
    });

    it('scrolls to requested line when rendered', () => {
      const linetoBeHighlighted = wrapper.find('#LC2');
      expect(scrollIntoViewMock).toHaveBeenCalled();
      expect(wrapper.vm.highlightedLine).toBe(linetoBeHighlighted.element);
      expect(linetoBeHighlighted.classes()).toContain(HIGHLIGHT_CLASS_NAME);
    });

    it('switches highlighting when another line is selected', async () => {
      const currentlyHighlighted = wrapper.find('#LC2');
      const hash = '#LC3';
      const linetoBeHighlighted = wrapper.find(hash);

      expect(wrapper.vm.highlightedLine).toBe(currentlyHighlighted.element);

      wrapper.vm.scrollToLine(hash);

      await nextTick();
      expect(wrapper.vm.highlightedLine).toBe(linetoBeHighlighted.element);
      expect(currentlyHighlighted.classes()).not.toContain(HIGHLIGHT_CLASS_NAME);
      expect(linetoBeHighlighted.classes()).toContain(HIGHLIGHT_CLASS_NAME);
    });
  });
});
