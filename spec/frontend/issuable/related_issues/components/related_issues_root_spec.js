import { mount, shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import {
  defaultProps,
  issuable1,
  issuable2,
} from 'jest/vue_shared/components/issue/related_issuable_mock_data';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import RelatedIssuesRoot from '~/related_issues/components/related_issues_root.vue';
import { linkedIssueTypesMap } from '~/related_issues/constants';
import relatedIssuesService from '~/related_issues/services/related_issues_service';

jest.mock('~/flash');

describe('RelatedIssuesRoot', () => {
  let wrapper;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(defaultProps.endpoint).reply(200, []);
  });

  afterEach(() => {
    mock.restore();
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const createComponent = (mountFn = mount) => {
    wrapper = mountFn(RelatedIssuesRoot, {
      propsData: defaultProps,
    });

    // Wait for fetch request `fetchRelatedIssues` to complete before starting to test
    return waitForPromises();
  };

  describe('methods', () => {
    describe('onRelatedIssueRemoveRequest', () => {
      beforeEach(() => {
        jest
          .spyOn(relatedIssuesService.prototype, 'fetchRelatedIssues')
          .mockReturnValue(Promise.reject());

        return createComponent().then(() => {
          wrapper.vm.store.setRelatedIssues([issuable1]);
        });
      });

      it('remove related issue and succeeds', () => {
        mock.onDelete(issuable1.referencePath).reply(200, { issues: [] });

        wrapper.vm.onRelatedIssueRemoveRequest(issuable1.id);

        return axios.waitForAll().then(() => {
          expect(wrapper.vm.state.relatedIssues).toEqual([]);
        });
      });

      it('remove related issue, fails, and restores to related issues', () => {
        mock.onDelete(issuable1.referencePath).reply(422, {});

        wrapper.vm.onRelatedIssueRemoveRequest(issuable1.id);

        return axios.waitForAll().then(() => {
          expect(wrapper.vm.state.relatedIssues).toHaveLength(1);
          expect(wrapper.vm.state.relatedIssues[0].id).toEqual(issuable1.id);
        });
      });
    });

    describe('onToggleAddRelatedIssuesForm', () => {
      beforeEach(() => createComponent(shallowMount));

      it('toggle related issues form to visible', () => {
        wrapper.vm.onToggleAddRelatedIssuesForm();

        expect(wrapper.vm.isFormVisible).toEqual(true);
      });

      it('show add related issues form to hidden', () => {
        wrapper.vm.isFormVisible = true;

        wrapper.vm.onToggleAddRelatedIssuesForm();

        expect(wrapper.vm.isFormVisible).toEqual(false);
      });
    });

    describe('onPendingIssueRemoveRequest', () => {
      beforeEach(() =>
        createComponent().then(() => {
          wrapper.vm.store.setPendingReferences([issuable1.reference]);
        }),
      );

      it('remove pending related issue', () => {
        expect(wrapper.vm.state.pendingReferences).toHaveLength(1);

        wrapper.vm.onPendingIssueRemoveRequest(0);

        expect(wrapper.vm.state.pendingReferences).toHaveLength(0);
      });
    });

    describe('onPendingFormSubmit', () => {
      beforeEach(() => {
        jest
          .spyOn(relatedIssuesService.prototype, 'fetchRelatedIssues')
          .mockReturnValue(Promise.reject());

        return createComponent().then(() => {
          jest.spyOn(wrapper.vm, 'processAllReferences');
          jest.spyOn(wrapper.vm.service, 'addRelatedIssues');
          createFlash.mockClear();
        });
      });

      it('processes references before submitting', () => {
        const input = '#123';
        const linkedIssueType = linkedIssueTypesMap.RELATES_TO;
        const emitObj = {
          pendingReferences: input,
          linkedIssueType,
        };

        wrapper.vm.onPendingFormSubmit(emitObj);

        expect(wrapper.vm.processAllReferences).toHaveBeenCalledWith(input);
        expect(wrapper.vm.service.addRelatedIssues).toHaveBeenCalledWith([input], linkedIssueType);
      });

      it('submit zero pending issue as related issue', () => {
        wrapper.vm.store.setPendingReferences([]);
        wrapper.vm.onPendingFormSubmit({});

        return waitForPromises().then(() => {
          expect(wrapper.vm.state.pendingReferences).toHaveLength(0);
          expect(wrapper.vm.state.relatedIssues).toHaveLength(0);
        });
      });

      it('submit pending issue as related issue', () => {
        mock.onPost(defaultProps.endpoint).reply(200, {
          issuables: [issuable1],
          result: {
            message: 'something was successfully related',
            status: 'success',
          },
        });

        wrapper.vm.store.setPendingReferences([issuable1.reference]);
        wrapper.vm.onPendingFormSubmit({});

        return waitForPromises().then(() => {
          expect(wrapper.vm.state.pendingReferences).toHaveLength(0);
          expect(wrapper.vm.state.relatedIssues).toHaveLength(1);
          expect(wrapper.vm.state.relatedIssues[0].id).toEqual(issuable1.id);
        });
      });

      it('submit multiple pending issues as related issues', () => {
        mock.onPost(defaultProps.endpoint).reply(200, {
          issuables: [issuable1, issuable2],
          result: {
            message: 'something was successfully related',
            status: 'success',
          },
        });

        wrapper.vm.store.setPendingReferences([issuable1.reference, issuable2.reference]);
        wrapper.vm.onPendingFormSubmit({});

        return waitForPromises().then(() => {
          expect(wrapper.vm.state.pendingReferences).toHaveLength(0);
          expect(wrapper.vm.state.relatedIssues).toHaveLength(2);
          expect(wrapper.vm.state.relatedIssues[0].id).toEqual(issuable1.id);
          expect(wrapper.vm.state.relatedIssues[1].id).toEqual(issuable2.id);
        });
      });

      it('displays a message from the backend upon error', () => {
        const input = '#123';
        const message = 'error';

        mock.onPost(defaultProps.endpoint).reply(409, { message });
        wrapper.vm.store.setPendingReferences([issuable1.reference, issuable2.reference]);

        expect(createFlash).not.toHaveBeenCalled();
        wrapper.vm.onPendingFormSubmit(input);

        return waitForPromises().then(() => {
          expect(createFlash).toHaveBeenCalledWith({
            message,
          });
        });
      });
    });

    describe('onPendingFormCancel', () => {
      beforeEach(() =>
        createComponent().then(() => {
          wrapper.vm.isFormVisible = true;
          wrapper.vm.inputValue = 'foo';
        }),
      );

      it('when canceling and hiding add issuable form', () => {
        wrapper.vm.onPendingFormCancel();

        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.isFormVisible).toEqual(false);
          expect(wrapper.vm.inputValue).toEqual('');
          expect(wrapper.vm.state.pendingReferences).toHaveLength(0);
        });
      });
    });

    describe('fetchRelatedIssues', () => {
      beforeEach(() => createComponent());

      it('sets isFetching while fetching', () => {
        wrapper.vm.fetchRelatedIssues();

        expect(wrapper.vm.isFetching).toEqual(true);

        return waitForPromises().then(() => {
          expect(wrapper.vm.isFetching).toEqual(false);
        });
      });

      it('should fetch related issues', () => {
        mock.onGet(defaultProps.endpoint).reply(200, [issuable1, issuable2]);

        wrapper.vm.fetchRelatedIssues();

        return waitForPromises().then(() => {
          expect(wrapper.vm.state.relatedIssues).toHaveLength(2);
          expect(wrapper.vm.state.relatedIssues[0].id).toEqual(issuable1.id);
          expect(wrapper.vm.state.relatedIssues[1].id).toEqual(issuable2.id);
        });
      });
    });

    describe('onInput', () => {
      beforeEach(() => createComponent());

      it('fill in issue number reference and adds to pending related issues', () => {
        const input = '#123 ';
        wrapper.vm.onInput({
          untouchedRawReferences: [input.trim()],
          touchedReference: input,
        });

        expect(wrapper.vm.state.pendingReferences).toHaveLength(1);
        expect(wrapper.vm.state.pendingReferences[0]).toEqual('#123');
      });

      it('fill in with full reference', () => {
        const input = 'asdf/qwer#444 ';
        wrapper.vm.onInput({ untouchedRawReferences: [input.trim()], touchedReference: input });

        expect(wrapper.vm.state.pendingReferences).toHaveLength(1);
        expect(wrapper.vm.state.pendingReferences[0]).toEqual('asdf/qwer#444');
      });

      it('fill in with issue link', () => {
        const link = 'http://localhost:3000/foo/bar/issues/111';
        const input = `${link} `;
        wrapper.vm.onInput({ untouchedRawReferences: [input.trim()], touchedReference: input });

        expect(wrapper.vm.state.pendingReferences).toHaveLength(1);
        expect(wrapper.vm.state.pendingReferences[0]).toEqual(link);
      });

      it('fill in with multiple references', () => {
        const input = 'asdf/qwer#444 #12 ';
        wrapper.vm.onInput({
          untouchedRawReferences: input.trim().split(/\s/),
          touchedReference: '2',
        });

        expect(wrapper.vm.state.pendingReferences).toHaveLength(2);
        expect(wrapper.vm.state.pendingReferences[0]).toEqual('asdf/qwer#444');
        expect(wrapper.vm.state.pendingReferences[1]).toEqual('#12');
      });

      it('fill in with some invalid things', () => {
        const input = 'something random ';
        wrapper.vm.onInput({
          untouchedRawReferences: input.trim().split(/\s/),
          touchedReference: '2',
        });

        expect(wrapper.vm.state.pendingReferences).toHaveLength(2);
        expect(wrapper.vm.state.pendingReferences[0]).toEqual('something');
        expect(wrapper.vm.state.pendingReferences[1]).toEqual('random');
      });

      it('prepends # when user enters a numeric value [0-9]', async () => {
        const input = '23';

        wrapper.vm.onInput({
          untouchedRawReferences: input.trim().split(/\s/),
          touchedReference: input,
        });

        expect(wrapper.vm.inputValue).toBe(`#${input}`);
      });

      it('prepends # when user enters a number', async () => {
        const input = 23;

        wrapper.vm.onInput({
          untouchedRawReferences: String(input).trim().split(/\s/),
          touchedReference: input,
        });

        expect(wrapper.vm.inputValue).toBe(`#${input}`);
      });
    });

    describe('onBlur', () => {
      beforeEach(() =>
        createComponent().then(() => {
          jest.spyOn(wrapper.vm, 'processAllReferences').mockImplementation(() => {});
        }),
      );

      it('add any references to pending when blurring', () => {
        const input = '#123';

        wrapper.vm.onBlur(input);

        expect(wrapper.vm.processAllReferences).toHaveBeenCalledWith(input);
      });
    });

    describe('processAllReferences', () => {
      beforeEach(() => createComponent());

      it('add valid reference to pending', () => {
        const input = '#123';
        wrapper.vm.processAllReferences(input);

        expect(wrapper.vm.state.pendingReferences).toHaveLength(1);
        expect(wrapper.vm.state.pendingReferences[0]).toEqual('#123');
      });

      it('add any valid references to pending', () => {
        const input = 'asdf #123';
        wrapper.vm.processAllReferences(input);

        expect(wrapper.vm.state.pendingReferences).toHaveLength(2);
        expect(wrapper.vm.state.pendingReferences[0]).toEqual('asdf');
        expect(wrapper.vm.state.pendingReferences[1]).toEqual('#123');
      });
    });
  });
});
