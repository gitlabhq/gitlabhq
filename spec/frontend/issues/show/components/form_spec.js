import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { getDraft, updateDraft, clearDraft, getLockVersion } from '~/lib/utils/autosave';
import DescriptionTemplate from '~/issues/show/components/fields/description_template.vue';
import IssuableTitleField from '~/issues/show/components/fields/title.vue';
import DescriptionField from '~/issues/show/components/fields/description.vue';
import IssueTypeField from '~/issues/show/components/fields/type.vue';
import formComponent from '~/issues/show/components/form.vue';
import LockedWarning from '~/issues/show/components/locked_warning.vue';
import eventHub from '~/issues/show/event_hub';

jest.mock('~/lib/utils/autosave');

describe('Inline edit form component', () => {
  let wrapper;
  const defaultProps = {
    canDestroy: true,
    endpoint: 'gitlab-org/gitlab-test/-/issues/1',
    formState: {
      title: 'b',
      description: 'a',
      lockedWarningVisible: false,
    },
    issuableType: 'issue',
    markdownPreviewPath: '/',
    markdownDocsPath: '/',
    projectPath: '/',
    projectId: 1,
    projectNamespace: '/',
  };

  const createComponent = (props) => {
    wrapper = shallowMount(formComponent, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        DescriptionField,
      },
    });
  };

  const findTitleField = () => wrapper.findComponent(IssuableTitleField);
  const findDescriptionField = () => wrapper.findComponent(DescriptionField);
  const findDescriptionTemplate = () => wrapper.findComponent(DescriptionTemplate);
  const findIssuableTypeField = () => wrapper.findComponent(IssueTypeField);
  const findLockedWarning = () => wrapper.findComponent(LockedWarning);
  const findAlert = () => wrapper.findComponent(GlAlert);

  it('does not render template selector if no templates exist', () => {
    createComponent();

    expect(findDescriptionTemplate().exists()).toBe(false);
  });

  it('renders template selector when templates as array exists', () => {
    createComponent({
      issuableTemplates: [
        { name: 'test', id: 'test', project_path: 'test', namespace_path: 'test' },
      ],
    });

    expect(findDescriptionTemplate().exists()).toBe(true);
  });

  it('renders template selector when templates as hash exists', () => {
    createComponent({
      issuableTemplates: {
        test: [{ name: 'test', id: 'test', project_path: 'test', namespace_path: 'test' }],
      },
    });

    expect(findDescriptionTemplate().exists()).toBe(true);
  });

  it.each`
    issuableType | value
    ${'issue'}   | ${true}
    ${'epic'}    | ${false}
  `(
    'when `issue_type` is set to "$issuableType" rendering the type select will be "$value"',
    ({ issuableType, value }) => {
      createComponent({
        issuableType,
      });

      expect(findIssuableTypeField().exists()).toBe(value);
    },
  );

  it('hides locked warning by default', () => {
    createComponent();

    expect(findLockedWarning().exists()).toBe(false);
  });

  it('shows locked warning if formState is different', () => {
    createComponent({ formState: { ...defaultProps.formState, lockedWarningVisible: true } });

    expect(findLockedWarning().exists()).toBe(true);
  });

  it('hides locked warning when currently saving', () => {
    createComponent({
      formState: { ...defaultProps.formState, updateLoading: true, lockedWarningVisible: true },
    });

    expect(findLockedWarning().exists()).toBe(false);
  });

  describe('autosave', () => {
    beforeEach(() => {
      getDraft.mockImplementation((autosaveKey) => {
        return autosaveKey[autosaveKey.length - 1];
      });
    });

    it('initializes title and description fields with saved drafts', () => {
      createComponent();

      expect(findTitleField().props().value).toBe('title');
      expect(findDescriptionField().props().value).toBe('description');
    });

    it('updates local storage drafts when title and description change', () => {
      const updatedTitle = 'updated title';
      const updatedDescription = 'updated description';

      createComponent();

      findTitleField().vm.$emit('input', updatedTitle);
      findDescriptionField().vm.$emit('input', updatedDescription);

      expect(updateDraft).toHaveBeenCalledWith(expect.any(Array), updatedTitle);
      expect(updateDraft).toHaveBeenCalledWith(
        expect.any(Array),
        updatedDescription,
        defaultProps.formState.lock_version,
      );
    });

    it('calls reset on autosave when eventHub emits appropriate events', () => {
      createComponent();

      eventHub.$emit('close.form');

      expect(clearDraft).toHaveBeenCalledTimes(2);

      eventHub.$emit('delete.issuable');

      expect(clearDraft).toHaveBeenCalledTimes(4);

      eventHub.$emit('update.issuable');

      expect(clearDraft).toHaveBeenCalledTimes(6);
    });

    describe('outdated description', () => {
      const clientSideMockVersion = 'lock version from local storage';
      const serverSideMockVersion = 'lock version from server';

      const mockGetLockVersion = () => getLockVersion.mockResolvedValue(clientSideMockVersion);

      it('does not show warning if lock version from server is the same as the local lock version', () => {
        createComponent();
        expect(findAlert().exists()).toBe(false);
      });

      it('shows warning if lock version from server differs than the local lock version', async () => {
        mockGetLockVersion();

        createComponent({
          formState: { ...defaultProps.formState, lock_version: serverSideMockVersion },
        });

        await nextTick();
        expect(findAlert().exists()).toBe(true);
      });

      describe('when saved draft is discarded', () => {
        beforeEach(async () => {
          mockGetLockVersion();

          createComponent({
            formState: { ...defaultProps.formState, lock_version: serverSideMockVersion },
          });

          await nextTick();

          findAlert().vm.$emit('secondaryAction');
        });

        it('hides the warning alert', () => {
          expect(findAlert().exists()).toBe(false);
        });

        it('clears the description draft', () => {
          expect(clearDraft).toHaveBeenCalledWith(expect.any(Array));
        });
      });
    });
  });
});
