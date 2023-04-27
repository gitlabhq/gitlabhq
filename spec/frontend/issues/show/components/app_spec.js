import { GlIcon, GlIntersectionObserver } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import {
  issuableStatusText,
  STATUS_CLOSED,
  STATUS_OPEN,
  STATUS_REOPENED,
  TYPE_EPIC,
  TYPE_ISSUE,
} from '~/issues/constants';
import IssuableApp from '~/issues/show/components/app.vue';
import DescriptionComponent from '~/issues/show/components/description.vue';
import EditedComponent from '~/issues/show/components/edited.vue';
import FormComponent from '~/issues/show/components/form.vue';
import TitleComponent from '~/issues/show/components/title.vue';
import IncidentTabs from '~/issues/show/components/incidents/incident_tabs.vue';
import PinnedLinks from '~/issues/show/components/pinned_links.vue';
import eventHub from '~/issues/show/event_hub';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_UNAUTHORIZED } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';
import {
  appProps,
  initialRequest,
  publishedIncidentUrl,
  putRequest,
  secondRequest,
  zoomMeetingUrl,
} from '../mock_data/mock_data';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility');
jest.mock('~/behaviors/markdown/render_gfm');

const REALTIME_REQUEST_STACK = [initialRequest, secondRequest];

describe('Issuable output', () => {
  let axiosMock;
  let wrapper;

  const findStickyHeader = () => wrapper.findByTestId('issue-sticky-header');
  const findLockedBadge = () => wrapper.findByTestId('locked');
  const findConfidentialBadge = () => wrapper.findByTestId('confidential');
  const findHiddenBadge = () => wrapper.findByTestId('hidden');

  const findTitle = () => wrapper.findComponent(TitleComponent);
  const findDescription = () => wrapper.findComponent(DescriptionComponent);
  const findEdited = () => wrapper.findComponent(EditedComponent);
  const findForm = () => wrapper.findComponent(FormComponent);
  const findPinnedLinks = () => wrapper.findComponent(PinnedLinks);

  const createComponent = ({ props = {}, options = {}, data = {} } = {}) => {
    wrapper = shallowMountExtended(IssuableApp, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: { ...appProps, ...props },
      provide: {
        fullPath: 'gitlab-org/incidents',
        uploadMetricsFeatureAvailable: false,
      },
      stubs: {
        HighlightBar: true,
        IncidentTabs: true,
      },
      data() {
        return {
          ...data,
        };
      },
      ...options,
    });

    jest.advanceTimersToNextTimer(2);
    return waitForPromises();
  };

  const emitHubEvent = (event) => {
    eventHub.$emit(event);
    return waitForPromises();
  };

  const openForm = () => {
    return emitHubEvent('open.form');
  };

  const updateIssuable = () => {
    return emitHubEvent('update.issuable');
  };

  const advanceToNextPoll = () => {
    // We get new data through the HTTP request.
    jest.advanceTimersToNextTimer();
    return waitForPromises();
  };

  beforeEach(() => {
    jest.spyOn(eventHub, '$emit');

    axiosMock = new MockAdapter(axios);
    const endpoint = '/gitlab-org/gitlab-shell/-/issues/9/realtime_changes/realtime_changes';

    axiosMock.onGet(endpoint).replyOnce(HTTP_STATUS_OK, REALTIME_REQUEST_STACK[0], {
      'POLL-INTERVAL': '1',
    });
    axiosMock.onGet(endpoint).reply(HTTP_STATUS_OK, REALTIME_REQUEST_STACK[1], {
      'POLL-INTERVAL': '-1',
    });
    axiosMock.onPut().reply(HTTP_STATUS_OK, putRequest);
  });

  describe('update', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('should render a title/description/edited and update title/description/edited on update', async () => {
      expect(findTitle().props('titleText')).toContain(initialRequest.title_text);
      expect(findDescription().props('descriptionText')).toContain('this is a description');

      expect(findEdited().exists()).toBe(true);
      expect(findEdited().props('updatedByPath')).toMatch(/\/some_user$/);
      expect(findEdited().props('updatedAt')).toBe(initialRequest.updated_at);
      expect(findDescription().props().lockVersion).toBe(initialRequest.lock_version);

      await advanceToNextPoll();

      expect(findTitle().props('titleText')).toContain('2');
      expect(findDescription().props('descriptionText')).toContain('42');

      expect(findEdited().exists()).toBe(true);
      expect(findEdited().props('updatedByName')).toBe('Other User');
      expect(findEdited().props('updatedByPath')).toMatch(/\/other_user$/);
      expect(findEdited().props('updatedAt')).toBe(secondRequest.updated_at);
    });
  });

  describe('with permissions', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('shows actions on `open.form` event', async () => {
      expect(findForm().exists()).toBe(false);

      await openForm();

      expect(findForm().exists()).toBe(true);
    });

    it('update formState if form is not open', async () => {
      const titleValue = initialRequest.title_text;

      expect(findTitle().exists()).toBe(true);
      expect(findTitle().props('titleText')).toBe(titleValue);

      await advanceToNextPoll();

      // The title component has the new data, so the state was updated
      expect(findTitle().exists()).toBe(true);
      expect(findTitle().props('titleText')).toBe(secondRequest.title_text);
    });

    it('does not update formState if form is already open', async () => {
      const titleValue = initialRequest.title_text;

      expect(findTitle().exists()).toBe(true);
      expect(findTitle().props('titleText')).toBe(titleValue);

      await openForm();

      // Opening the form, the data has not changed
      expect(findForm().props().formState.title).toBe(titleValue);

      await advanceToNextPoll();

      // We expect the prop value not to have changed after another API call
      expect(findForm().props().formState.title).toBe(titleValue);
    });
  });

  describe('without permissions', () => {
    beforeEach(async () => {
      await createComponent({ props: { canUpdate: false } });
    });

    it('does not show actions if permissions are incorrect', async () => {
      await openForm();

      expect(findForm().exists()).toBe(false);
    });
  });

  describe('Pinned links propagated', () => {
    it.each`
      prop                      | value
      ${'zoomMeetingUrl'}       | ${zoomMeetingUrl}
      ${'publishedIncidentUrl'} | ${publishedIncidentUrl}
    `('sets the $prop correctly on underlying pinned links', async ({ prop, value }) => {
      await createComponent();

      expect(findPinnedLinks().props(prop)).toBe(value);
    });
  });

  describe('updating an issue', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('fetches new data after update', async () => {
      await advanceToNextPoll();

      await updateIssuable();

      expect(axiosMock.history.put).toHaveLength(1);
      // The call was made with the new data
      expect(axiosMock.history.put[0].data.title).toEqual(findTitle().props().title);
    });

    it('closes the form after fetching data', async () => {
      await updateIssuable();

      expect(eventHub.$emit).toHaveBeenCalledWith('close.form');
    });

    it('does not redirect if issue has not moved', async () => {
      axiosMock.onPut().reply(HTTP_STATUS_OK, {
        ...putRequest,
        confidential: appProps.isConfidential,
      });

      await updateIssuable();

      expect(visitUrl).not.toHaveBeenCalled();
    });

    it('does not redirect if issue has not moved and user has switched tabs', async () => {
      axiosMock.onPut().reply(HTTP_STATUS_OK, {
        ...putRequest,
        web_url: '',
        confidential: appProps.isConfidential,
      });

      await updateIssuable();

      expect(visitUrl).not.toHaveBeenCalled();
    });

    it('redirects if returned web_url has changed', async () => {
      const webUrl = '/testing-issue-move';

      axiosMock.onPut().reply(HTTP_STATUS_OK, {
        ...putRequest,
        web_url: webUrl,
        confidential: appProps.isConfidential,
      });

      await updateIssuable();

      expect(visitUrl).toHaveBeenCalledWith(webUrl);
    });

    describe('error when updating', () => {
      it('closes form', async () => {
        axiosMock.onPut().reply(HTTP_STATUS_UNAUTHORIZED);

        await updateIssuable();

        expect(eventHub.$emit).not.toHaveBeenCalledWith('close.form');
        expect(createAlert).toHaveBeenCalledWith({
          message: `Error updating issue. Request failed with status code 401`,
        });
      });

      it('returns the correct error message for issuableType', async () => {
        axiosMock.onPut().reply(HTTP_STATUS_UNAUTHORIZED);

        await updateIssuable();

        wrapper.setProps({ issuableType: 'merge request' });

        await updateIssuable();

        expect(eventHub.$emit).not.toHaveBeenCalledWith('close.form');
        expect(createAlert).toHaveBeenCalledWith({
          message: `Error updating merge request. Request failed with status code 401`,
        });
      });

      it('shows error message from backend if exists', async () => {
        const msg = 'Custom error message from backend';
        axiosMock.onPut().reply(HTTP_STATUS_UNAUTHORIZED, { errors: [msg] });

        await updateIssuable();

        expect(createAlert).toHaveBeenCalledWith({
          message: `Error updating issue. ${msg}`,
        });
      });
    });
  });

  describe('Locked warning', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('shows locked warning if form is open & data is different', async () => {
      await openForm();
      await advanceToNextPoll();

      expect(findForm().props().formState.lockedWarningVisible).toBe(true);
      expect(findForm().props().formState.lock_version).toBe(1);
    });
  });

  describe('sticky header', () => {
    beforeEach(async () => {
      await createComponent();
    });

    describe('when title is in view', () => {
      it('is not shown', () => {
        expect(findStickyHeader().exists()).toBe(false);
      });
    });

    describe('when title is not in view', () => {
      beforeEach(() => {
        wrapper.findComponent(GlIntersectionObserver).vm.$emit('disappear');
      });

      it('shows with title', () => {
        expect(findStickyHeader().text()).toContain(initialRequest.title_text);
      });

      it('shows with title for an epic', async () => {
        await wrapper.setProps({ issuableType: 'epic' });

        expect(findStickyHeader().text()).toContain(' this is a title');
      });

      it.each`
        issuableType  | issuableStatus   | statusIcon
        ${TYPE_ISSUE} | ${STATUS_OPEN}   | ${'issues'}
        ${TYPE_ISSUE} | ${STATUS_CLOSED} | ${'issue-closed'}
        ${TYPE_EPIC}  | ${STATUS_OPEN}   | ${'epic'}
        ${TYPE_EPIC}  | ${STATUS_CLOSED} | ${'epic-closed'}
      `(
        'shows with state icon "$statusIcon" for $issuableType when status is $issuableStatus',
        async ({ issuableType, issuableStatus, statusIcon }) => {
          await wrapper.setProps({ issuableType, issuableStatus });

          expect(findStickyHeader().findComponent(GlIcon).props('name')).toBe(statusIcon);
        },
      );

      it.each`
        title                                        | state
        ${'shows with Open when status is opened'}   | ${STATUS_OPEN}
        ${'shows with Closed when status is closed'} | ${STATUS_CLOSED}
        ${'shows with Open when status is reopened'} | ${STATUS_REOPENED}
      `('$title', async ({ state }) => {
        await wrapper.setProps({ issuableStatus: state });

        expect(findStickyHeader().text()).toContain(issuableStatusText[state]);
      });

      it.each`
        title                                                                | isConfidential
        ${'does not show confidential badge when issue is not confidential'} | ${false}
        ${'shows confidential badge when issue is confidential'}             | ${true}
      `('$title', async ({ isConfidential }) => {
        await wrapper.setProps({ isConfidential });

        const confidentialEl = findConfidentialBadge();
        expect(confidentialEl.exists()).toBe(isConfidential);
        if (isConfidential) {
          expect(confidentialEl.props()).toMatchObject({
            workspaceType: 'project',
            issuableType: 'issue',
          });
        }
      });

      it.each`
        title                                                    | isLocked
        ${'does not show locked badge when issue is not locked'} | ${false}
        ${'shows locked badge when issue is locked'}             | ${true}
      `('$title', async ({ isLocked }) => {
        await wrapper.setProps({ isLocked });

        expect(findLockedBadge().exists()).toBe(isLocked);
      });

      it.each`
        title                                                    | isHidden
        ${'does not show hidden badge when issue is not hidden'} | ${false}
        ${'shows hidden badge when issue is hidden'}             | ${true}
      `('$title', async ({ isHidden }) => {
        await wrapper.setProps({ isHidden });

        const hiddenBadge = findHiddenBadge();

        expect(hiddenBadge.exists()).toBe(isHidden);

        if (isHidden) {
          expect(hiddenBadge.attributes('title')).toBe(
            'This issue is hidden because its author has been banned',
          );
          expect(getBinding(hiddenBadge.element, 'gl-tooltip')).not.toBeUndefined();
        }
      });
    });
  });

  describe('Composable description component', () => {
    beforeEach(async () => {
      await createComponent();
    });

    const findIncidentTabs = () => wrapper.findComponent(IncidentTabs);
    const borderClass = 'gl-border-b-1 gl-border-b-gray-100 gl-border-b-solid gl-mb-6';

    describe('when using description component', () => {
      it('renders the description component', () => {
        expect(findDescription().exists()).toBe(true);
      });

      it('does not render incident tabs', () => {
        expect(findIncidentTabs().exists()).toBe(false);
      });

      it('adds a border below the header', () => {
        expect(findPinnedLinks().attributes('class')).toContain(borderClass);
      });
    });

    describe('when using incident tabs description wrapper', () => {
      beforeEach(async () => {
        await createComponent({
          props: {
            descriptionComponent: IncidentTabs,
            showTitleBorder: false,
          },
          options: {
            mocks: {
              $apollo: {
                queries: {
                  alert: {
                    loading: false,
                  },
                },
              },
            },
          },
        });
      });

      it('does not the description component', () => {
        expect(findDescription().exists()).toBe(false);
      });

      it('renders incident tabs', () => {
        expect(findIncidentTabs().exists()).toBe(true);
      });

      it('does not add a border below the header', () => {
        expect(findPinnedLinks().attributes('class')).not.toContain(borderClass);
      });
    });
  });

  describe('taskListUpdateStarted', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('stops polling', async () => {
      expect(findTitle().props().titleText).toBe(initialRequest.title_text);

      findDescription().vm.$emit('taskListUpdateStarted');

      await advanceToNextPoll();

      expect(findTitle().props().titleText).toBe(initialRequest.title_text);
    });
  });

  describe('taskListUpdateSucceeded', () => {
    beforeEach(async () => {
      await createComponent();
      findDescription().vm.$emit('taskListUpdateStarted');
    });

    it('enables polling', async () => {
      // Ensure that polling is not working before
      expect(findTitle().props().titleText).toBe(initialRequest.title_text);
      await advanceToNextPoll();

      expect(findTitle().props().titleText).toBe(initialRequest.title_text);

      // Enable Polling an move forward
      findDescription().vm.$emit('taskListUpdateSucceeded');
      await advanceToNextPoll();

      // Title has changed: polling works!
      expect(findTitle().props().titleText).toBe(secondRequest.title_text);
    });
  });

  describe('taskListUpdateFailed', () => {
    beforeEach(async () => {
      await createComponent();
      findDescription().vm.$emit('taskListUpdateStarted');
    });

    it('enables polling and calls updateStoreState', async () => {
      // Ensure that polling is not working before
      expect(findTitle().props().titleText).toBe(initialRequest.title_text);
      await advanceToNextPoll();

      expect(findTitle().props().titleText).toBe(initialRequest.title_text);

      // Enable Polling an move forward
      findDescription().vm.$emit('taskListUpdateFailed');
      await advanceToNextPoll();

      // Title has changed: polling works!
      expect(findTitle().props().titleText).toBe(secondRequest.title_text);
    });
  });

  describe('saveDescription event', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('makes request to update issue', async () => {
      const description = 'I have been updated!';
      findDescription().vm.$emit('saveDescription', description);

      await waitForPromises();

      expect(axiosMock.history.put[0].data).toContain(description);
    });
  });
});
