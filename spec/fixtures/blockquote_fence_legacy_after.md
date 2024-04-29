TODO: This is now a legacy filter, and is only used with the Ruby parser.
The current markdown parser now properly handles multiline block quotes.
The Ruby parser is now only for benchmarking purposes.
issue: https://gitlab.com/gitlab-org/gitlab/-/issues/454601

Single `>>>` inside code block:

```
# Code
>>>
# Code
```

Double `>>>` inside code block:

```txt
# Code
>>>
# Code
>>>
# Code
```

Blockquote outside code block:


> Quote


Code block inside blockquote:


> Quote
>
> ```
> # Code
> ```
>
> Quote


Single `>>>` inside code block inside blockquote:


> Quote
>
> ```
> # Code
> >>>
> # Code
> ```
>
> Quote


Double `>>>` inside code block inside blockquote:


> Quote
>
> ```
> # Code
> >>>
> # Code
> >>>
> # Code
> ```
>
> Quote


Single `>>>` inside HTML:

<pre>
# Code
>>>
# Code
</pre>

Double `>>>` inside HTML:

<pre>
# Code
>>>
# Code
>>>
# Code
</pre>

Blockquote outside HTML:


> Quote


HTML inside blockquote:


> Quote
>
> <pre>
> # Code
> </pre>
>
> Quote


Single `>>>` inside HTML inside blockquote:


> Quote
>
> <pre>
> # Code
> >>>
> # Code
> </pre>
>
> Quote


Double `>>>` inside HTML inside blockquote:


> Quote
>
> <pre>
> # Code
> >>>
> # Code
> >>>
> # Code
> </pre>
>
> Quote


Blockquote inside an unordered list

- Item one


  > Foo and
  > bar


  - Sub item


    > Foo


Blockquote inside an ordered list

1. Item one


   > Bar


   1. Sub item


      > Foo


Requires a leading blank line
>>>
Not a quote
>>>

Requires a trailing blank line

>>>
Not a quote
>>>
Lorem

Triple quoting is not our blockquote

>>> foo
>>> bar
>>>
> baz

> boo
>>> far
>>>
>>> faz
