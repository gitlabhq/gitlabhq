<template>
  <div>
    <!--  singular text (`__`)  -->
    <span data-expected="singular_translated">
      {{ __('singular') }}
    </span>
    <!--  plural text (`n__`) without any substituting text  -->
    <span data-expected="plural_singular translation">
      {{ n__('plural', 'plurals', 1) }}
    </span>
    <span data-expected="plural_multiple translation">
      {{ n__('plural', 'plurals', 2) }}
    </span>
    <!--  plural text (`n__`) with substituting %d  -->
    <span data-expected="1 singular translated">
      {{ n__('%d day', '%d days', 1) }}
    </span>
    <span data-expected="2 plural translated">
      {{ n__('%d day', '%d days', 2) }}
    </span>
    <!-- text with context `s__` -->
    <span data-expected="Foobar translated">
      {{ s__('Context', 'Foobar') }}
    </span>
    <span data-expected="Foobar translated">
      {{ s__('Context|Foobar') }}
    </span>
    <!--  multi line text  -->
    <span data-expected="multiline string translated">
      {{
        __(`
            multiline
            string
            `)
      }}
    </span>
    <!--  pluralized line text  -->
    <span data-expected="multiline string plural">
      {{
        n__(
          `
            multiline
            plural
            `,
          `
            multiline
            plurals
            `,
          2,
        )
      }}
    </span>
    <!--    multi line text with context -->
    <span data-expected="multiline string with context">
      {{
        s__(
          `
            Context|
            multiline
            string
            `,
        )
      }}
    </span>
  </div>
</template>
