import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import '~/behaviors/markdown/render_gfm';
import issuableApp from '~/issue_show/components/app.vue';
import eventHub from '~/issue_show/event_hub';
import { initialRequest, secondRequest } from '../mock_data';

function formatText(text) {
  return text.trim().replace(/\s\s+/g, ' ');
}

jest.mock('~/lib/utils/url_utility');
jest.mock('~/issue_show/event_hub');

const REALTIME_REQUEST_STACK = [initialRequest, secondRequest];

describe('Issuable output', () => {
  let mock;
  let realtimeRequestCount = 0;
  let vm;

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

    const IssuableDescriptionComponent = Vue.extend(issuableApp);

    mock = new MockAdapter(axios);
    mock
      .onGet('/gitlab-org/gitlab-shell/-/issues/9/realtime_changes/realtime_changes')
      .reply(() => {
        const res = Promise.resolve([200, REALTIME_REQUEST_STACK[realtimeRequestCount]]);
        realtimeRequestCount += 1;
        return res;
      });

    vm = new IssuableDescriptionComponent({
      propsData: {
        canUpdate: true,
        canDestroy: true,
        endpoint: '/gitlab-org/gitlab-shell/-/issues/9/realtime_changes',
        updateEndpoint: TEST_HOST,
        issuableRef: '#1',
        initialTitleHtml: '',
        initialTitleText: '',
        initialDescriptionHtml: 'test',
        initialDescriptionText: 'test',
        lockVersion: 1,
        markdownPreviewPath: '/',
        markdownDocsPath: '/',
        projectNamespace: '/',
        projectPath: '/',
        issuableTemplateNamesPath: '/issuable-templates-path',
      },
    }).$mount();
  });

  afterEach(() => {
    mock.restore();
    realtimeRequestCount = 0;

    vm.poll.stop();
    vm.$destroy();
  });

  it('should render a title/description/edited and update title/description/edited on update', () => {
    let editedText;
    return axios
      .waitForAll()
      .then(() => {
        editedText = vm.$el.querySelector('.edited-text');
      })
      .then(() => {
        expect(document.querySelector('title').innerText).toContain('this is a title (#1)');
        expect(vm.$el.querySelector('.title').innerHTML).toContain('<p>this is a title</p>');
        expect(vm.$el.querySelector('.md').innerHTML).toContain('<p>this is a description!</p>');
        expect(vm.$el.querySelector('.js-task-list-field').value).toContain(
          'this is a description',
        );

        expect(formatText(editedText.innerText)).toMatch(/Edited[\s\S]+?by Some User/);
        expect(editedText.querySelector('.author-link').href).toMatch(/\/some_user$/);
        expect(editedText.querySelector('time')).toBeTruthy();
        expect(vm.state.lock_version).toEqual(1);
      })
      .then(() => {
        vm.poll.makeRequest();
        return axios.waitForAll();
      })
      .then(() => {
        expect(document.querySelector('title').innerText).toContain('2 (#1)');
        expect(vm.$el.querySelector('.title').innerHTML).toContain('<p>2</p>');
        expect(vm.$el.querySelector('.md').innerHTML).toContain('<p>42</p>');
        expect(vm.$el.querySelector('.js-task-list-field').value).toContain('42');
        expect(vm.$el.querySelector('.edited-text')).toBeTruthy();
        expect(formatText(vm.$el.querySelector('.edited-text').innerText)).toMatch(
          /Edited[\s\S]+?by Other User/,
        );

        expect(editedText.querySelector('.author-link').href).toMatch(/\/other_user$/);
        expect(editedText.querySelector('time')).toBeTruthy();
        expect(vm.state.lock_version).toEqual(2);
      });
  });

  it('shows actions if permissions are correct', () => {
    vm.showForm = true;

    return vm.$nextTick().then(() => {
      expect(vm.$el.querySelector('.btn')).not.toBeNull();
    });
  });

  it('does not show actions if permissions are incorrect', () => {
    vm.showForm = true;
    vm.canUpdate = false;

    return vm.$nextTick().then(() => {
      expect(vm.$el.querySelector('.btn')).toBeNull();
    });
  });

  it('does not update formState if form is already open', () => {
    vm.updateAndShowForm();

    vm.state.titleText = 'testing 123';

    vm.updateAndShowForm();

    return vm.$nextTick().then(() => {
      expect(vm.store.formState.title).not.toBe('testing 123');
    });
  });

  it('opens reCAPTCHA modal if update rejected as spam', () => {
    let modal;

    jest.spyOn(vm.service, 'updateIssuable').mockResolvedValue({
      data: {
        recaptcha_html: '<div class="g-recaptcha">recaptcha_html</div>',
      },
    });

    vm.canUpdate = true;
    vm.showForm = true;

    return vm
      .$nextTick()
      .then(() => {
        vm.$refs.recaptchaModal.scriptSrc = '//scriptsrc';
        return vm.updateIssuable();
      })
      .then(() => {
        modal = vm.$el.querySelector('.js-recaptcha-modal');

        expect(modal.style.display).not.toEqual('none');
        expect(modal.querySelector('.g-recaptcha').textContent).toEqual('recaptcha_html');
        expect(document.body.querySelector('.js-recaptcha-script').src).toMatch('//scriptsrc');
      })
      .then(() => {
        modal.querySelector('.close').click();
        return vm.$nextTick();
      })
      .then(() => {
        expect(modal.style.display).toEqual('none');
        expect(document.body.querySelector('.js-recaptcha-script')).toBeNull();
      });
  });

  describe('updateIssuable', () => {
    it('fetches new data after update', () => {
      const updateStoreSpy = jest.spyOn(vm, 'updateStoreState');
      const getDataSpy = jest.spyOn(vm.service, 'getData');
      jest.spyOn(vm.service, 'updateIssuable').mockResolvedValue({
        data: { web_url: window.location.pathname },
      });

      return vm.updateIssuable().then(() => {
        expect(updateStoreSpy).toHaveBeenCalled();
        expect(getDataSpy).toHaveBeenCalled();
      });
    });

    it('correctly updates issuable data', () => {
      const spy = jest.spyOn(vm.service, 'updateIssuable').mockResolvedValue({
        data: { web_url: window.location.pathname },
      });

      return vm.updateIssuable().then(() => {
        expect(spy).toHaveBeenCalledWith(vm.formState);
        expect(eventHub.$emit).toHaveBeenCalledWith('close.form');
      });
    });

    it('does not redirect if issue has not moved', () => {
      jest.spyOn(vm.service, 'updateIssuable').mockResolvedValue({
        data: {
          web_url: window.location.pathname,
          confidential: vm.isConfidential,
        },
      });

      return vm.updateIssuable().then(() => {
        expect(visitUrl).not.toHaveBeenCalled();
      });
    });

    it('redirects if returned web_url has changed', () => {
      jest.spyOn(vm.service, 'updateIssuable').mockResolvedValue({
        data: {
          web_url: '/testing-issue-move',
          confidential: vm.isConfidential,
        },
      });

      vm.updateIssuable();

      return vm.updateIssuable().then(() => {
        expect(visitUrl).toHaveBeenCalledWith('/testing-issue-move');
      });
    });

    describe('shows dialog when issue has unsaved changed', () => {
      it('confirms on title change', () => {
        vm.showForm = true;
        vm.state.titleText = 'title has changed';
        const e = { returnValue: null };
        vm.handleBeforeUnloadEvent(e);
        return vm.$nextTick().then(() => {
          expect(e.returnValue).not.toBeNull();
        });
      });

      it('confirms on description change', () => {
        vm.showForm = true;
        vm.state.descriptionText = 'description has changed';
        const e = { returnValue: null };
        vm.handleBeforeUnloadEvent(e);
        return vm.$nextTick().then(() => {
          expect(e.returnValue).not.toBeNull();
        });
      });

      it('does nothing when nothing has changed', () => {
        const e = { returnValue: null };
        vm.handleBeforeUnloadEvent(e);
        return vm.$nextTick().then(() => {
          expect(e.returnValue).toBeNull();
        });
      });
    });

    describe('error when updating', () => {
      it('closes form on error', () => {
        jest.spyOn(vm.service, 'updateIssuable').mockRejectedValue();
        return vm.updateIssuable().then(() => {
          expect(eventHub.$emit).not.toHaveBeenCalledWith('close.form');
          expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
            `Error updating issue`,
          );
        });
      });

      it('returns the correct error message for issuableType', () => {
        jest.spyOn(vm.service, 'updateIssuable').mockRejectedValue();
        vm.issuableType = 'merge request';

        return vm
          .$nextTick()
          .then(vm.updateIssuable)
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
          .spyOn(vm.service, 'updateIssuable')
          .mockRejectedValue({ response: { data: { errors: [msg] } } });

        return vm.updateIssuable().then(() => {
          expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
            `${vm.defaultErrorMessage}. ${msg}`,
          );
        });
      });
    });
  });

  describe('deleteIssuable', () => {
    it('changes URL when deleted', () => {
      jest.spyOn(vm.service, 'deleteIssuable').mockResolvedValue({
        data: {
          web_url: '/test',
        },
      });

      return vm.deleteIssuable().then(() => {
        expect(visitUrl).toHaveBeenCalledWith('/test');
      });
    });

    it('stops polling when deleting', () => {
      const spy = jest.spyOn(vm.poll, 'stop');
      jest.spyOn(vm.service, 'deleteIssuable').mockResolvedValue({
        data: {
          web_url: '/test',
        },
      });

      return vm.deleteIssuable().then(() => {
        expect(spy).toHaveBeenCalledWith();
      });
    });

    it('closes form on error', () => {
      jest.spyOn(vm.service, 'deleteIssuable').mockRejectedValue();

      return vm.deleteIssuable().then(() => {
        expect(eventHub.$emit).not.toHaveBeenCalledWith('close.form');
        expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
          'Error deleting issue',
        );
      });
    });
  });

  describe('updateAndShowForm', () => {
    it('shows locked warning if form is open & data is different', () => {
      return vm
        .$nextTick()
        .then(() => {
          vm.updateAndShowForm();

          vm.poll.makeRequest();

          return new Promise(resolve => {
            vm.$watch('formState.lockedWarningVisible', value => {
              if (value) resolve();
            });
          });
        })
        .then(() => {
          expect(vm.formState.lockedWarningVisible).toEqual(true);
          expect(vm.formState.lock_version).toEqual(1);
          expect(vm.$el.querySelector('.alert')).not.toBeNull();
        });
    });
  });

  describe('requestTemplatesAndShowForm', () => {
    let formSpy;

    beforeEach(() => {
      formSpy = jest.spyOn(vm, 'updateAndShowForm');
    });

    it('shows the form if template names request is successful', () => {
      const mockData = [{ name: 'Bug' }];
      mock.onGet('/issuable-templates-path').reply(() => Promise.resolve([200, mockData]));

      return vm.requestTemplatesAndShowForm().then(() => {
        expect(formSpy).toHaveBeenCalledWith(mockData);
      });
    });

    it('shows the form if template names request failed', () => {
      mock
        .onGet('/issuable-templates-path')
        .reply(() => Promise.reject(new Error('something went wrong')));

      return vm.requestTemplatesAndShowForm().then(() => {
        expect(document.querySelector('.flash-container .flash-text').textContent).toContain(
          'Error updating issue',
        );

        expect(formSpy).toHaveBeenCalledWith();
      });
    });
  });

  describe('show inline edit button', () => {
    it('should not render by default', () => {
      expect(vm.$el.querySelector('.title-container .note-action-button')).toBeDefined();
    });

    it('should render if showInlineEditButton', () => {
      vm.showInlineEditButton = true;

      expect(vm.$el.querySelector('.title-container .note-action-button')).toBeDefined();
    });
  });

  describe('updateStoreState', () => {
    it('should make a request and update the state of the store', () => {
      const data = { foo: 1 };
      const getDataSpy = jest.spyOn(vm.service, 'getData').mockResolvedValue({ data });
      const updateStateSpy = jest.spyOn(vm.store, 'updateState').mockImplementation(jest.fn);

      return vm.updateStoreState().then(() => {
        expect(getDataSpy).toHaveBeenCalled();
        expect(updateStateSpy).toHaveBeenCalledWith(data);
      });
    });

    it('should show error message if store update fails', () => {
      jest.spyOn(vm.service, 'getData').mockRejectedValue();
      vm.issuableType = 'merge request';

      return vm.updateStoreState().then(() => {
        expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
          `Error updating ${vm.issuableType}`,
        );
      });
    });
  });

  describe('issueChanged', () => {
    beforeEach(() => {
      vm.store.formState.title = '';
      vm.store.formState.description = '';
      vm.initialDescriptionText = '';
      vm.initialTitleText = '';
    });

    it('returns true when title is changed', () => {
      vm.store.formState.title = 'RandomText';

      expect(vm.issueChanged).toBe(true);
    });

    it('returns false when title is empty null', () => {
      vm.store.formState.title = null;

      expect(vm.issueChanged).toBe(false);
    });

    it('returns false when `initialTitleText` is null and `formState.title` is empty string', () => {
      vm.store.formState.title = '';
      vm.initialTitleText = null;

      expect(vm.issueChanged).toBe(false);
    });

    it('returns true when description is changed', () => {
      vm.store.formState.description = 'RandomText';

      expect(vm.issueChanged).toBe(true);
    });

    it('returns false when description is empty null', () => {
      vm.store.formState.title = null;

      expect(vm.issueChanged).toBe(false);
    });

    it('returns false when `initialDescriptionText` is null and `formState.description` is empty string', () => {
      vm.store.formState.description = '';
      vm.initialDescriptionText = null;

      expect(vm.issueChanged).toBe(false);
    });
  });
});
