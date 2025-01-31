import { GlIcon, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ChangedFileIcon from '~/vue_shared/components/changed_file_icon.vue';

const changedFile = () => ({ changed: true });
const stagedFile = () => ({ changed: true, staged: true });
const newFile = () => ({ changed: true, tempFile: true });
const deletedFile = () => ({ changed: false, tempFile: false, staged: false, deleted: true });
const unchangedFile = () => ({ changed: false, tempFile: false, staged: false, deleted: false });

describe('Changed file icon', () => {
  let wrapper;

  const factory = (props = {}) => {
    wrapper = shallowMount(ChangedFileIcon, {
      propsData: {
        file: changedFile(),
        showTooltip: true,
        ...props,
      },
    });
  };

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findIconName = () => findIcon().props('name');
  const findIconClasses = () => findIcon().classes();
  const findTooltipText = () => wrapper.attributes('title');
  const findIconWrapper = () => wrapper.findComponent(GlButton);

  it('with isCentered true, adds center class', () => {
    factory({
      isCentered: true,
    });

    expect(wrapper.classes('ml-auto')).toBe(true);
  });

  it('with isCentered false, does not center', () => {
    factory({
      isCentered: false,
    });

    expect(wrapper.classes('ml-auto')).toBe(false);
  });

  it('with showTooltip false, does not show tooltip', () => {
    factory({
      showTooltip: false,
    });

    expect(findTooltipText()).toBeUndefined();
  });

  describe.each`
    file             | iconName                 | tooltipText   | desc
    ${changedFile()} | ${'file-modified'}       | ${'Modified'} | ${'with file changed'}
    ${stagedFile()}  | ${'file-modified-solid'} | ${'Modified'} | ${'with file staged'}
    ${newFile()}     | ${'file-addition'}       | ${'Added'}    | ${'with file new'}
    ${deletedFile()} | ${'file-deletion'}       | ${'Deleted'}  | ${'with file deleted'}
  `('$desc', ({ file, iconName, tooltipText }) => {
    beforeEach(() => {
      factory({ file });
    });

    it('renders icon', () => {
      expect(findIconWrapper().exists()).toBe(true);
      expect(findIconName()).toBe(iconName);
      expect(findIconClasses()).toContain(iconName);
    });

    it('renders tooltip text', () => {
      expect(findTooltipText()).toBe(tooltipText);
    });
  });

  describe('with file unchanged', () => {
    beforeEach(() => {
      factory({
        file: unchangedFile(),
      });
    });

    it('does not show icon and a tooltip associated with it', () => {
      expect(findIconWrapper().exists()).toBe(false);
    });
  });

  it('with size set, sets icon size', () => {
    const size = 8;

    factory({
      file: changedFile(),
      size,
    });

    expect(findIcon().props('size')).toBe(size);
  });

  it.each`
    showStagedIcon | iconName                 | desc
    ${true}        | ${'file-modified-solid'} | ${'with showStagedIcon true, renders staged icon'}
    ${false}       | ${'file-modified'}       | ${'with showStagedIcon false, renders regular icon'}
  `('$desc', ({ showStagedIcon, iconName }) => {
    factory({
      file: stagedFile(),
      showStagedIcon,
    });

    expect(findIconName()).toEqual(iconName);
  });
});
