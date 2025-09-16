<!-- eslint-disable vue/multi-word-component-names -->
<template>
  <thead>
    <tr>
      <th id="name" scope="col">{{ s__('ProjectFileTree|Name') }}</th>
      <th id="last-commit" scope="col" class="gl-hidden @sm/panel:gl-table-cell">
        {{ __('Last commit') }}
      </th>
      <th id="last-update" scope="col" class="!gl-text-right">{{ __('Last update') }}</th>
    </tr>
  </thead>
</template>
