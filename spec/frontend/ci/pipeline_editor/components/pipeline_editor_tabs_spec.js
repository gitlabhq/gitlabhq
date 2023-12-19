import { GlAlert, GlBadge, GlLoadingIcon, GlTabs } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import CiConfigMergedPreview from '~/ci/pipeline_editor/components/editor/ci_config_merged_preview.vue';
import CiValidate from '~/ci/pipeline_editor/components/validate/ci_validate.vue';
import WalkthroughPopover from '~/ci/pipeline_editor/components/popovers/walkthrough_popover.vue';
import PipelineEditorTabs from '~/ci/pipeline_editor/components/pipeline_editor_tabs.vue';
import EditorTab from '~/ci/pipeline_editor/components/ui/editor_tab.vue';
import {
  CREATE_TAB,
  EDITOR_APP_STATUS_EMPTY,
  EDITOR_APP_STATUS_LOADING,
  EDITOR_APP_STATUS_INVALID,
  EDITOR_APP_STATUS_VALID,
  TAB_QUERY_PARAM,
  VALIDATE_TAB,
  VALIDATE_TAB_BADGE_DISMISSED_KEY,
} from '~/ci/pipeline_editor/constants';
import PipelineGraph from '~/ci/pipeline_editor/components/graph/pipeline_graph.vue';
import getBlobContent from '~/ci/pipeline_editor/graphql/queries/blob_content.query.graphql';
import {
  mockBlobContentQueryResponse,
  mockCiLintPath,
  mockCiYml,
  mockLintResponse,
  mockLintResponseWithoutMerged,
} from '../mock_data';

Vue.use(VueApollo);

Vue.config.ignoredElements = ['gl-emoji'];

describe('Pipeline editor tabs component', () => {
  let wrapper;
  const MockTextEditor = {
    template: '<div />',
  };

  const createComponent = ({
    listeners = {},
    props = {},
    provide = {},
    appStatus = EDITOR_APP_STATUS_VALID,
    mountFn = shallowMount,
    options = {},
  } = {}) => {
    wrapper = mountFn(PipelineEditorTabs, {
      propsData: {
        ciConfigData: mockLintResponse,
        ciFileContent: mockCiYml,
        currentTab: CREATE_TAB,
        isNewCiConfigFile: true,
        showHelpDrawer: false,
        showJobAssistantDrawer: false,
        showAiAssistantDrawer: false,
        ...props,
      },
      data() {
        return {
          appStatus,
        };
      },
      provide: {
        aiChatAvailable: false,
        ciCatalogPath: '/explore/catalog',
        ciConfigPath: '/path/to/ci-config',
        ciLintPath: mockCiLintPath,
        currentBranch: 'main',
        projectFullPath: '/path/to/project',
        simulatePipelineHelpPagePath: 'path/to/help/page',
        validateTabIllustrationPath: 'path/to/svg',
        ...provide,
      },
      stubs: {
        TextEditor: MockTextEditor,
        EditorTab,
      },
      listeners,
      ...options,
    });
  };

  let mockBlobContentData;
  let mockApollo;

  const createComponentWithApollo = ({ props, provide = {}, mountFn = shallowMount } = {}) => {
    const handlers = [[getBlobContent, mockBlobContentData]];
    mockApollo = createMockApollo(handlers);

    createComponent({
      props,
      provide,
      mountFn,
      options: {
        apolloProvider: mockApollo,
      },
    });
  };

  const findEditorTab = () => wrapper.find('[data-testid="editor-tab"]');
  const findMergedTab = () => wrapper.find('[data-testid="merged-tab"]');
  const findValidateTab = () => wrapper.find('[data-testid="validate-tab"]');
  const findVisualizationTab = () => wrapper.find('[data-testid="visualization-tab"]');

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findCiValidate = () => wrapper.findComponent(CiValidate);
  const findGlTabs = () => wrapper.findComponent(GlTabs);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findPipelineGraph = () => wrapper.findComponent(PipelineGraph);
  const findTextEditor = () => wrapper.findComponent(MockTextEditor);
  const findMergedPreview = () => wrapper.findComponent(CiConfigMergedPreview);
  const findWalkthroughPopover = () => wrapper.findComponent(WalkthroughPopover);

  beforeEach(() => {
    mockBlobContentData = jest.fn();
  });

  afterEach(() => {
    // eslint-disable-next-line @gitlab/vtu-no-explicit-wrapper-destroy
    wrapper.destroy();
  });

  describe('editor tab', () => {
    it('displays editor only after the tab is mounted', async () => {
      mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponse);
      createComponentWithApollo({ mountFn: mount });

      expect(findTextEditor().exists()).toBe(false);

      await nextTick();

      expect(findTextEditor().exists()).toBe(true);
      expect(findEditorTab().exists()).toBe(true);
    });
  });

  describe('visualization tab', () => {
    describe('while loading', () => {
      beforeEach(() => {
        createComponent({ appStatus: EDITOR_APP_STATUS_LOADING });
      });

      it('displays a loading icon if the lint query is loading', () => {
        expect(findLoadingIcon().exists()).toBe(true);
        expect(findPipelineGraph().exists()).toBe(false);
      });
    });
    describe('after loading', () => {
      beforeEach(() => {
        createComponent();
      });

      it('display the tab and visualization', () => {
        expect(findVisualizationTab().exists()).toBe(true);
        expect(findPipelineGraph().exists()).toBe(true);
      });
    });
  });

  describe('validate tab', () => {
    describe('after loading', () => {
      beforeEach(() => {
        createComponent();
      });

      it('displays the tab and the validate component', () => {
        expect(findValidateTab().exists()).toBe(true);
        expect(findCiValidate().exists()).toBe(true);
      });
    });

    describe('NEW badge', () => {
      describe('default', () => {
        beforeEach(() => {
          mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponse);
          createComponentWithApollo({
            mountFn: mount,
            props: {
              currentTab: VALIDATE_TAB,
            },
          });
        });

        it('renders badge by default', () => {
          expect(findBadge().exists()).toBe(true);
          expect(findBadge().text()).toBe(wrapper.vm.$options.i18n.new);
        });

        it('hides badge when moving away from the validate tab', async () => {
          expect(findBadge().exists()).toBe(true);

          await findEditorTab().vm.$emit('click');

          expect(findBadge().exists()).toBe(false);
        });
      });

      describe('if badge has been dismissed before', () => {
        beforeEach(() => {
          localStorage.setItem(VALIDATE_TAB_BADGE_DISMISSED_KEY, 'true');
          mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponse);
          createComponentWithApollo({ mountFn: mount });
        });

        it('does not render badge if it has been dismissed before', () => {
          expect(findBadge().exists()).toBe(false);
        });
      });
    });
  });

  describe('merged tab', () => {
    describe('while loading', () => {
      beforeEach(() => {
        createComponent({ appStatus: EDITOR_APP_STATUS_LOADING });
      });

      it('displays a loading icon if the lint query is loading', () => {
        expect(findLoadingIcon().exists()).toBe(true);
      });
    });

    describe('when there is a fetch error', () => {
      beforeEach(() => {
        createComponent({ props: { ciConfigData: mockLintResponseWithoutMerged } });
      });

      it('show an error message', () => {
        expect(findAlert().exists()).toBe(true);
        expect(findAlert().text()).toBe(wrapper.vm.$options.errorTexts.loadMergedYaml);
      });

      it('does not render the `merged_preview` component', () => {
        expect(findMergedPreview().exists()).toBe(false);
      });
    });

    describe('after loading', () => {
      beforeEach(() => {
        createComponent();
      });

      it('display the tab and the merged preview component', () => {
        expect(findMergedTab().exists()).toBe(true);
        expect(findMergedPreview().exists()).toBe(true);
      });
    });
  });

  describe('show tab content based on status', () => {
    it.each`
      appStatus                    | editor  | viz      | validate | merged
      ${undefined}                 | ${true} | ${true}  | ${true}  | ${true}
      ${EDITOR_APP_STATUS_EMPTY}   | ${true} | ${false} | ${true}  | ${false}
      ${EDITOR_APP_STATUS_INVALID} | ${true} | ${false} | ${true}  | ${true}
      ${EDITOR_APP_STATUS_VALID}   | ${true} | ${true}  | ${true}  | ${true}
    `(
      'when status is $appStatus, we show - editor:$editor | viz:$viz | validate:$validate | merged:$merged',
      ({ appStatus, editor, viz, validate, merged }) => {
        createComponent({ appStatus });

        expect(findTextEditor().exists()).toBe(editor);
        expect(findPipelineGraph().exists()).toBe(viz);
        expect(findValidateTab().exists()).toBe(validate);
        expect(findMergedPreview().exists()).toBe(merged);
      },
    );
  });

  describe('default tab based on url query param', () => {
    const gitlabUrl = 'https://gitlab.test/ci/editor/';
    const matchObject = {
      hostname: 'gitlab.test',
      pathname: '/ci/editor/',
      search: '',
    };

    it(`is ${CREATE_TAB} if the query param ${TAB_QUERY_PARAM} is not present`, () => {
      setWindowLocation(gitlabUrl);
      createComponent();

      expect(window.location).toMatchObject(matchObject);
    });

    it(`is ${CREATE_TAB} tab if the query param ${TAB_QUERY_PARAM} is invalid`, () => {
      const queryValue = 'FOO';
      setWindowLocation(`${gitlabUrl}?${TAB_QUERY_PARAM}=${queryValue}`);
      createComponent();

      // If the query param remains unchanged, then we have ignored it.
      expect(window.location).toMatchObject({
        ...matchObject,
        search: `?${TAB_QUERY_PARAM}=${queryValue}`,
      });
    });
  });

  describe('glTabs', () => {
    beforeEach(() => {
      createComponent();
    });

    it('passes the `sync-active-tab-with-query-params` prop', () => {
      expect(findGlTabs().props('syncActiveTabWithQueryParams')).toBe(true);
    });
  });

  describe('pipeline editor walkthrough', () => {
    describe('when isNewCiConfigFile prop is true (default)', () => {
      beforeEach(() => {
        createComponent();
      });

      it('shows walkthrough popover', () => {
        expect(findWalkthroughPopover().exists()).toBe(true);
      });
    });

    describe('when isNewCiConfigFile prop is false', () => {
      it('does not show walkthrough popover', () => {
        createComponent({ props: { isNewCiConfigFile: false } });
        expect(findWalkthroughPopover().exists()).toBe(false);
      });
    });
  });

  it('sets listeners on walkthrough popover', async () => {
    const handler = jest.fn();

    createComponent({
      listeners: {
        event: handler,
      },
    });
    await nextTick();

    findWalkthroughPopover().vm.$emit('event');

    expect(handler).toHaveBeenCalled();
  });
});
