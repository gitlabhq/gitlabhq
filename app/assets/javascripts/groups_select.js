import Vue from 'vue';
import GroupSelect from '~/vue_shared/components/group_select/group_select.vue';

const initVueSelect = () => {
  [...document.querySelectorAll('.ajax-groups-select')].forEach((el) => {
    const { parentId: parentGroupID, groupsFilter, inputId } = el.dataset;

    return new Vue({
      el,
      components: {
        GroupSelect,
      },
      render(createElement) {
        return createElement(GroupSelect, {
          props: {
            inputName: el.name,
            initialSelection: el.value || null,
            parentGroupID,
            groupsFilter,
            inputId,
            clearable: el.classList.contains('allowClear'),
          },
        });
      },
    });
  });
};

export default () => {
  initVueSelect();
};
