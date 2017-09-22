<script>
  export default {
    props: {
      analyticsData: {
        type: Object,
        required: true,
      },
      startDate: {
        type: Number,
        required: true,
      },
    },
    methods: {
      onClickDropdown(value) {
        this.$emit('onClickDropdown', value);
      },
    },
  };
</script>
<template>
  <div class="panel panel-default">
    <div class="panel-heading">
      {{ __('Pipeline Health') }}
    </div>
    <div class="content-block">
      <div class="row">
        <div
          class="col-sm-3 col-xs-12 column"
          v-for="(item, i) in analyticsData.summary"
          :key="i">
          <h3 class="header">
            {{item.value}}
          </h3>
          <p class="text">
            {{item.title}}
          </p>
        </div>
        <div class="col-sm-3 col-xs-12 column">
          <div class="dropdown prepend-top-10">
            <button
              type="button"
              data-toggle="dropdown"
              class="dropdown-menu-toggle">
              <span class="dropdown-label">
                {{ n__('Last %d day', 'Last %d days', startDate) }}
              </span>
              <i
                class="fa fa-chevron-down"
                aria-hidden="true">
              </i>
            </button>
            <ul class="dropdown-menu dropdowm-menu-align-right">
              <li>
                <a @click="onClickDropdown(7)">
                  {{ n__('Last %d day', 'Last %d days', 7) }}
                </a>
              </li>
              <li>
                <a @click="onClickDropdown(30)">
                  {{ n__('Last %d day', 'Last %d days', 30) }}
                </a>
              </li>
              <li>
                <a @click="onClickDropdown(90)">
                  {{ n__('Last %d day', 'Last %d days', 90) }}
                </a>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
