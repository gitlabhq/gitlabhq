<template>
  <div class="mr-version-controls">
    <div class="mr-version-menus-container content-block">
      Changes between
      <span class="dropdown inline mr-version-dropdown">
        <a
          class="dropdown-toggle btn btn-default"
          data-toggle="dropdown"
          aria-expanded="false"
        >
          <span>
            latest version
          </span>
          <i
            aria-hidden="true"
            data-hidden="true"
            class="fa fa-caret-down"
          ></i>
        </a>
      </span>
      and
      <span class="dropdown inline mr-version-compare-dropdown">
        <a
          class="btn btn-default dropdown-toggle"
          data-toggle="dropdown"
          aria-expanded="false"
        >
          <span class="ref-name">master</span>
          <i
            aria-hidden="true"
            data-hidden="true"
            class="fa fa-caret-down"
          ></i>
        </a>
      </span>
    </div>
  </div>
</template>
