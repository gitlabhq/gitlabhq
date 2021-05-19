import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Autosave from '~/autosave';
import DescriptionTemplate from '~/issue_show/components/fields/description_template.vue';
import IssueTypeField from '~/issue_show/components/fields/type.vue';
import formComponent from '~/issue_show/components/form.vue';
import LockedWarning from '~/issue_show/components/locked_warning.vue';
import eventHub from '~/issue_show/event_hub';

jest.mock('~/autosave');

describe('Inline edit form component', () => {
  let wrapper;
  const defaultProps = {
    canDestroy: true,
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

  afterEach(() => {
    wrapper.destroy();
  });

  const createComponent = (props) => {
    wrapper = shallowMount(formComponent, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

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
    let spy;

    beforeEach(() => {
      spy = jest.spyOn(Autosave.prototype, 'reset');
    });

    it('initialized Autosave on mount', () => {
      createComponent();

      expect(Autosave).toHaveBeenCalledTimes(2);
    });

    it('calls reset on autosave when eventHub emits appropriate events', () => {
      createComponent();

      eventHub.$emit('close.form');

      expect(spy).toHaveBeenCalledTimes(2);

      eventHub.$emit('delete.issuable');

      expect(spy).toHaveBeenCalledTimes(4);

      eventHub.$emit('update.issuable');

      expect(spy).toHaveBeenCalledTimes(6);
    });

    describe('outdated description', () => {
      it('does not show warning if lock version from server is the same as the local lock version', () => {
        createComponent();
        expect(findAlert().exists()).toBe(false);
      });

      it('shows warning if lock version from server differs than the local lock version', async () => {
        Autosave.prototype.getSavedLockVersion.mockResolvedValue('lock version from local storage');

        createComponent({
          formState: { ...defaultProps.formState, lock_version: 'lock version from server' },
        });

        await wrapper.vm.$nextTick();
        expect(findAlert().exists()).toBe(true);
      });
    });
  });
});
