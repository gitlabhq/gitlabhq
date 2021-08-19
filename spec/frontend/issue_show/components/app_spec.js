import { GlIntersectionObserver } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import '~/behaviors/markdown/render_gfm';
import IssuableApp from '~/issue_show/components/app.vue';
import DescriptionComponent from '~/issue_show/components/description.vue';
import IncidentTabs from '~/issue_show/components/incidents/incident_tabs.vue';
import PinnedLinks from '~/issue_show/components/pinned_links.vue';
import { IssuableStatus, IssuableStatusText } from '~/issue_show/constants';
import eventHub from '~/issue_show/event_hub';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import {
  appProps,
  initialRequest,
  publishedIncidentUrl,
  secondRequest,
  zoomMeetingUrl,
} from '../mock_data/mock_data';

function formatText(text) {
  return text.trim().replace(/\s\s+/g, ' ');
}

jest.mock('~/lib/utils/url_utility');
jest.mock('~/issue_show/event_hub');

const REALTIME_REQUEST_STACK = [initialRequest, secondRequest];

describe('Issuable output', () => {
  let mock;
  let realtimeRequestCount = 0;
  let wrapper;

  const findStickyHeader = () => wrapper.find('[data-testid="issue-sticky-header"]');
  const findLockedBadge = () => wrapper.find('[data-testid="locked"]');
  const findConfidentialBadge = () => wrapper.find('[data-testid="confidential"]');
  const findAlert = () => wrapper.find('.alert');

  const mountComponent = (props = {}, options = {}, data = {}) => {
    wrapper = mount(IssuableApp, {
      propsData: { ...appProps, ...props },
      provide: {
        fullPath: 'gitlab-org/incidents',
        iid: '19',
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
  };

  beforeEach(() => {
    setFixtures(`
      <div>
        <title>Title</title>
        <div class="detail-page-description content-block">
        <details open>
          <summary>One</summary>
        </details>
        <details>
          <summary>Two</summary>
        </details>
      </div>
        <div class="flash-container"></div>
        <span id="task_status"></span>
      </div>
    `);

    mock = new MockAdapter(axios);
    mock
      .onGet('/gitlab-org/gitlab-shell/-/issues/9/realtime_changes/realtime_changes')
      .reply(() => {
        const res = Promise.resolve([200, REALTIME_REQUEST_STACK[realtimeRequestCount]]);
        realtimeRequestCount += 1;
        return res;
      });

    mountComponent();

    jest.advanceTimersByTime(2);
  });

  afterEach(() => {
    mock.restore();
    realtimeRequestCount = 0;
    wrapper.vm.poll.stop();
    wrapper.destroy();
  });

  it('should render a title/description/edited and update title/description/edited on update', () => {
    let editedText;
    return axios
      .waitForAll()
      .then(() => {
        editedText = wrapper.find('.edited-text');
      })
      .then(() => {
        expect(document.querySelector('title').innerText).toContain('this is a title (#1)');
        expect(wrapper.find('.title').text()).toContain('this is a title');
        expect(wrapper.find('.md').text()).toContain('this is a description!');
        expect(wrapper.find('.js-task-list-field').element.value).toContain(
          'this is a description',
        );

        expect(formatText(editedText.text())).toMatch(/Edited[\s\S]+?by Some User/);
        expect(editedText.find('.author-link').attributes('href')).toMatch(/\/some_user$/);
        expect(editedText.find('time').text()).toBeTruthy();
        expect(wrapper.vm.state.lock_version).toBe(initialRequest.lock_version);
      })
      .then(() => {
        wrapper.vm.poll.makeRequest();
        return axios.waitForAll();
      })
      .then(() => {
        expect(document.querySelector('title').innerText).toContain('2 (#1)');
        expect(wrapper.find('.title').text()).toContain('2');
        expect(wrapper.find('.md').text()).toContain('42');
        expect(wrapper.find('.js-task-list-field').element.value).toContain('42');
        expect(wrapper.find('.edited-text').text()).toBeTruthy();
        expect(formatText(wrapper.find('.edited-text').text())).toMatch(
          /Edited[\s\S]+?by Other User/,
        );

        expect(editedText.find('.author-link').attributes('href')).toMatch(/\/other_user$/);
        expect(editedText.find('time').text()).toBeTruthy();
        // As the lock_version value does not differ from the server,
        // we should not see an alert
        expect(findAlert().exists()).toBe(false);
      });
  });

  it('shows actions if permissions are correct', () => {
    wrapper.vm.showForm = true;

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.find('.markdown-selector').exists()).toBe(true);
    });
  });

  it('does not show actions if permissions are incorrect', () => {
    wrapper.vm.showForm = true;
    wrapper.setProps({ canUpdate: false });

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.find('.markdown-selector').exists()).toBe(false);
    });
  });

  it('does not update formState if form is already open', () => {
    wrapper.vm.updateAndShowForm();

    wrapper.vm.state.titleText = 'testing 123';

    wrapper.vm.updateAndShowForm();

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.vm.store.formState.title).not.toBe('testing 123');
    });
  });

  describe('Pinned links propagated', () => {
    it.each`
      prop                      | value
      ${'zoomMeetingUrl'}       | ${zoomMeetingUrl}
      ${'publishedIncidentUrl'} | ${publishedIncidentUrl}
    `('sets the $prop correctly on underlying pinned links', ({ prop, value }) => {
      expect(wrapper.vm[prop]).toBe(value);
      expect(wrapper.find(`[data-testid="${prop}"]`).attributes('href')).toBe(value);
    });
  });

  describe('updateIssuable', () => {
    it('fetches new data after update', () => {
      const updateStoreSpy = jest.spyOn(wrapper.vm, 'updateStoreState');
      const getDataSpy = jest.spyOn(wrapper.vm.service, 'getData');
      jest.spyOn(wrapper.vm.service, 'updateIssuable').mockResolvedValue({
        data: { web_url: window.location.pathname },
      });

      return wrapper.vm.updateIssuable().then(() => {
        expect(updateStoreSpy).toHaveBeenCalled();
        expect(getDataSpy).toHaveBeenCalled();
      });
    });

    it('correctly updates issuable data', () => {
      const spy = jest.spyOn(wrapper.vm.service, 'updateIssuable').mockResolvedValue({
        data: { web_url: window.location.pathname },
      });

      return wrapper.vm.updateIssuable().then(() => {
        expect(spy).toHaveBeenCalledWith(wrapper.vm.formState);
        expect(eventHub.$emit).toHaveBeenCalledWith('close.form');
      });
    });

    it('does not redirect if issue has not moved', () => {
      jest.spyOn(wrapper.vm.service, 'updateIssuable').mockResolvedValue({
        data: {
          web_url: window.location.pathname,
          confidential: wrapper.vm.isConfidential,
        },
      });

      return wrapper.vm.updateIssuable().then(() => {
        expect(visitUrl).not.toHaveBeenCalled();
      });
    });

    it('does not redirect if issue has not moved and user has switched tabs', () => {
      jest.spyOn(wrapper.vm.service, 'updateIssuable').mockResolvedValue({
        data: {
          web_url: '',
          confidential: wrapper.vm.isConfidential,
        },
      });

      return wrapper.vm.updateIssuable().then(() => {
        expect(visitUrl).not.toHaveBeenCalled();
      });
    });

    it('redirects if returned web_url has changed', () => {
      jest.spyOn(wrapper.vm.service, 'updateIssuable').mockResolvedValue({
        data: {
          web_url: '/testing-issue-move',
          confidential: wrapper.vm.isConfidential,
        },
      });

      wrapper.vm.updateIssuable();

      return wrapper.vm.updateIssuable().then(() => {
        expect(visitUrl).toHaveBeenCalledWith('/testing-issue-move');
      });
    });

    describe('shows dialog when issue has unsaved changed', () => {
      it('confirms on title change', () => {
        wrapper.vm.showForm = true;
        wrapper.vm.state.titleText = 'title has changed';
        const e = { returnValue: null };
        wrapper.vm.handleBeforeUnloadEvent(e);

        return wrapper.vm.$nextTick().then(() => {
          expect(e.returnValue).not.toBeNull();
        });
      });

      it('confirms on description change', () => {
        wrapper.vm.showForm = true;
        wrapper.vm.state.descriptionText = 'description has changed';
        const e = { returnValue: null };
        wrapper.vm.handleBeforeUnloadEvent(e);

        return wrapper.vm.$nextTick().then(() => {
          expect(e.returnValue).not.toBeNull();
        });
      });

      it('does nothing when nothing has changed', () => {
        const e = { returnValue: null };
        wrapper.vm.handleBeforeUnloadEvent(e);

        return wrapper.vm.$nextTick().then(() => {
          expect(e.returnValue).toBeNull();
        });
      });
    });

    describe('error when updating', () => {
      it('closes form on error', () => {
        jest.spyOn(wrapper.vm.service, 'updateIssuable').mockRejectedValue();

        return wrapper.vm.updateIssuable().then(() => {
          expect(eventHub.$emit).not.toHaveBeenCalledWith('close.form');
          expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
            `Error updating issue`,
          );
        });
      });

      it('returns the correct error message for issuableType', () => {
        jest.spyOn(wrapper.vm.service, 'updateIssuable').mockRejectedValue();
        wrapper.setProps({ issuableType: 'merge request' });

        return wrapper.vm
          .$nextTick()
          .then(wrapper.vm.updateIssuable)
          .then(() => {
            expect(eventHub.$emit).not.toHaveBeenCalledWith('close.form');
            expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
              `Error updating merge request`,
            );
          });
      });

      it('shows error message from backend if exists', () => {
        const msg = 'Custom error message from backend';
        jest
          .spyOn(wrapper.vm.service, 'updateIssuable')
          .mockRejectedValue({ response: { data: { errors: [msg] } } });

        return wrapper.vm.updateIssuable().then(() => {
          expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
            `${wrapper.vm.defaultErrorMessage}. ${msg}`,
          );
        });
      });
    });
  });

  describe('deleteIssuable', () => {
    it('changes URL when deleted', () => {
      jest.spyOn(wrapper.vm.service, 'deleteIssuable').mockResolvedValue({
        data: {
          web_url: '/test',
        },
      });

      return wrapper.vm.deleteIssuable().then(() => {
        expect(visitUrl).toHaveBeenCalledWith('/test');
      });
    });

    it('stops polling when deleting', () => {
      const spy = jest.spyOn(wrapper.vm.poll, 'stop');
      jest.spyOn(wrapper.vm.service, 'deleteIssuable').mockResolvedValue({
        data: {
          web_url: '/test',
        },
      });

      return wrapper.vm.deleteIssuable().then(() => {
        expect(spy).toHaveBeenCalledWith();
      });
    });

    it('closes form on error', () => {
      jest.spyOn(wrapper.vm.service, 'deleteIssuable').mockRejectedValue();

      return wrapper.vm.deleteIssuable().then(() => {
        expect(eventHub.$emit).not.toHaveBeenCalledWith('close.form');
        expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
          'Error deleting issue',
        );
      });
    });
  });

  describe('updateAndShowForm', () => {
    it('shows locked warning if form is open & data is different', () => {
      return wrapper.vm
        .$nextTick()
        .then(() => {
          wrapper.vm.updateAndShowForm();

          wrapper.vm.poll.makeRequest();

          return new Promise((resolve) => {
            wrapper.vm.$watch('formState.lockedWarningVisible', (value) => {
              if (value) {
                resolve();
              }
            });
          });
        })
        .then(() => {
          expect(wrapper.vm.formState.lockedWarningVisible).toBe(true);
          expect(wrapper.vm.formState.lock_version).toBe(1);
          expect(findAlert().exists()).toBe(true);
        });
    });
  });

  describe('requestTemplatesAndShowForm', () => {
    let formSpy;

    beforeEach(() => {
      formSpy = jest.spyOn(wrapper.vm, 'updateAndShowForm');
    });

    it('shows the form if template names as hash request is successful', () => {
      const mockData = {
        test: [{ name: 'test', id: 'test', project_path: '/', namespace_path: '/' }],
      };
      mock.onGet('/issuable-templates-path').reply(() => Promise.resolve([200, mockData]));

      return wrapper.vm.requestTemplatesAndShowForm().then(() => {
        expect(formSpy).toHaveBeenCalledWith(mockData);
      });
    });

    it('shows the form if template names as array request is successful', () => {
      const mockData = [{ name: 'test', id: 'test', project_path: '/', namespace_path: '/' }];
      mock.onGet('/issuable-templates-path').reply(() => Promise.resolve([200, mockData]));

      return wrapper.vm.requestTemplatesAndShowForm().then(() => {
        expect(formSpy).toHaveBeenCalledWith(mockData);
      });
    });

    it('shows the form if template names request failed', () => {
      mock
        .onGet('/issuable-templates-path')
        .reply(() => Promise.reject(new Error('something went wrong')));

      return wrapper.vm.requestTemplatesAndShowForm().then(() => {
        expect(document.querySelector('.flash-container .flash-text').textContent).toContain(
          'Error updating issue',
        );

        expect(formSpy).toHaveBeenCalledWith();
      });
    });
  });

  describe('show inline edit button', () => {
    it('should not render by default', () => {
      expect(wrapper.find('.btn-edit').exists()).toBe(true);
    });

    it('should render if showInlineEditButton', () => {
      wrapper.setProps({ showInlineEditButton: true });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find('.btn-edit').exists()).toBe(true);
      });
    });
  });

  describe('updateStoreState', () => {
    it('should make a request and update the state of the store', () => {
      const data = { foo: 1 };
      const getDataSpy = jest.spyOn(wrapper.vm.service, 'getData').mockResolvedValue({ data });
      const updateStateSpy = jest
        .spyOn(wrapper.vm.store, 'updateState')
        .mockImplementation(jest.fn);

      return wrapper.vm.updateStoreState().then(() => {
        expect(getDataSpy).toHaveBeenCalled();
        expect(updateStateSpy).toHaveBeenCalledWith(data);
      });
    });

    it('should show error message if store update fails', () => {
      jest.spyOn(wrapper.vm.service, 'getData').mockRejectedValue();
      wrapper.setProps({ issuableType: 'merge request' });

      return wrapper.vm.updateStoreState().then(() => {
        expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
          `Error updating ${wrapper.vm.issuableType}`,
        );
      });
    });
  });

  describe('issueChanged', () => {
    beforeEach(() => {
      wrapper.vm.store.formState.title = '';
      wrapper.vm.store.formState.description = '';
      wrapper.setProps({
        initialDescriptionText: '',
        initialTitleText: '',
      });
    });

    it('returns true when title is changed', () => {
      wrapper.vm.store.formState.title = 'RandomText';

      expect(wrapper.vm.issueChanged).toBe(true);
    });

    it('returns false when title is empty null', () => {
      wrapper.vm.store.formState.title = null;

      expect(wrapper.vm.issueChanged).toBe(false);
    });

    it('returns true when description is changed', () => {
      wrapper.vm.store.formState.description = 'RandomText';

      expect(wrapper.vm.issueChanged).toBe(true);
    });

    it('returns false when description is empty null', () => {
      wrapper.vm.store.formState.description = null;

      expect(wrapper.vm.issueChanged).toBe(false);
    });

    it('returns false when `initialDescriptionText` is null and `formState.description` is empty string', () => {
      wrapper.vm.store.formState.description = '';
      wrapper.setProps({ initialDescriptionText: null });

      expect(wrapper.vm.issueChanged).toBe(false);
    });
  });

  describe('sticky header', () => {
    describe('when title is in view', () => {
      it('is not shown', () => {
        expect(findStickyHeader().exists()).toBe(false);
      });
    });

    describe('when title is not in view', () => {
      beforeEach(() => {
        wrapper.vm.state.titleText = 'Sticky header title';
        wrapper.find(GlIntersectionObserver).vm.$emit('disappear');
      });

      it('shows with title', () => {
        expect(findStickyHeader().text()).toContain('Sticky header title');
      });

      it.each`
        title                                        | state
        ${'shows with Open when status is opened'}   | ${IssuableStatus.Open}
        ${'shows with Closed when status is closed'} | ${IssuableStatus.Closed}
        ${'shows with Open when status is reopened'} | ${IssuableStatus.Reopened}
      `('$title', async ({ state }) => {
        wrapper.setProps({ issuableStatus: state });

        await nextTick();

        expect(findStickyHeader().text()).toContain(IssuableStatusText[state]);
      });

      it.each`
        title                                                                | isConfidential
        ${'does not show confidential badge when issue is not confidential'} | ${true}
        ${'shows confidential badge when issue is confidential'}             | ${false}
      `('$title', async ({ isConfidential }) => {
        wrapper.setProps({ isConfidential });

        await nextTick();

        expect(findConfidentialBadge().exists()).toBe(isConfidential);
      });

      it.each`
        title                                                    | isLocked
        ${'does not show locked badge when issue is not locked'} | ${true}
        ${'shows locked badge when issue is locked'}             | ${false}
      `('$title', async ({ isLocked }) => {
        wrapper.setProps({ isLocked });

        await nextTick();

        expect(findLockedBadge().exists()).toBe(isLocked);
      });
    });
  });

  describe('Composable description component', () => {
    const findIncidentTabs = () => wrapper.findComponent(IncidentTabs);
    const findDescriptionComponent = () => wrapper.findComponent(DescriptionComponent);
    const findPinnedLinks = () => wrapper.findComponent(PinnedLinks);
    const borderClass = 'gl-border-b-1 gl-border-b-gray-100 gl-border-b-solid gl-mb-6';

    describe('when using description component', () => {
      it('renders the description component', () => {
        expect(findDescriptionComponent().exists()).toBe(true);
      });

      it('does not render incident tabs', () => {
        expect(findIncidentTabs().exists()).toBe(false);
      });

      it('adds a border below the header', () => {
        expect(findPinnedLinks().attributes('class')).toContain(borderClass);
      });
    });

    describe('when using incident tabs description wrapper', () => {
      beforeEach(() => {
        mountComponent(
          {
            descriptionComponent: IncidentTabs,
            showTitleBorder: false,
          },
          {
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
        );
      });

      it('renders the description component', () => {
        expect(findDescriptionComponent().exists()).toBe(true);
      });

      it('renders incident tabs', () => {
        expect(findIncidentTabs().exists()).toBe(true);
      });

      it('does not add a border below the header', () => {
        expect(findPinnedLinks().attributes('class')).not.toContain(borderClass);
      });
    });
  });
});
