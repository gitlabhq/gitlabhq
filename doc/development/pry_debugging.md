---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Pry debugging

## Invoking pry debugging

To invoke the debugger, place `binding.pry` somewhere in your
code. When the Ruby interpreter hits that code, execution stops,
and you can type in commands to debug the state of the program.

When debugging code in another process like Puma or Sidekiq, you can use `binding.pry_shell`.
You can then connect to this session by using the [pry-shell](https://github.com/meinac/pry-shell) executable.
You can watch [this video](https://www.youtube.com/watch?v=Lzs_PL_BySo), for more information about
how to use the `pry-shell`.

## `byebug` vs `binding.pry`

`byebug` has a very similar interface as `gdb`, but `byebug` does not
use the powerful Pry REPL.

`binding.pry` uses Pry, but lacks some of the `byebug`
features. GitLab uses the [`pry-byebug`](https://github.com/deivid-rodriguez/pry-byebug)
gem. This gem brings some capabilities `byebug` to `binding.pry`, so
using that gives you the most debugging powers.

## `byebug`

Check out [the docs](https://github.com/deivid-rodriguez/byebug) for the full list of commands.

You can start the Pry REPL with the `pry` command.

## `pry`

There are **a lot** of features present in `pry`, too much to cover in
this document, so for the full documentation head over to the [Pry wiki](https://github.com/pry/pry/wiki).

Below are a few features definitely worth checking out, also run
`help` in a pry session to see what else you can do.

### State navigation

With the [state navigation](https://github.com/pry/pry/wiki/State-navigation)
you can move around in the code to discover methods and such:

```ruby
# Change context
[1] pry(main)> cd Pry
[2] pry(Pry):1>

# Print methods
[2] pry(Pry):1> ls -m

# Find a method
[3] pry(Pry):1> find-method to_yaml
```

### Source browsing

You [look at the source code](https://github.com/pry/pry/wiki/Source-browsing)
from your `pry` session:

```ruby
[1] pry(main)> $ Array#first
# The above is equivalent to
[2] pry(main)> cd Array
[3] pry(Array):1> show-source first
```

`$` is an alias for `show-source`.

### Documentation browsing

Similar to source browsing, is [Documentation browsing](https://github.com/pry/pry/wiki/Documentation-browsing).

```ruby
[1] pry(main)> show-doc Array#first
```

`?` is an alias for `show-doc`.

### Command history

With <kbd>Control</kbd> + <kbd>R</kbd> you can search your [command history](https://github.com/pry/pry/wiki/History).

## Stepping

To step through the code, you can use the following commands:

- `break`: Manage breakpoints.
- `step`: Step execution into the next line or method. Takes an
  optional numeric argument to step multiple times.
- `next`: Step over to the next line within the same frame. Also takes
  an optional numeric argument to step multiple lines.
- `finish`: Execute until current stack frame returns.
- `continue`: Continue program execution and end the Pry session.

## Callstack navigation

You also can move around in the callstack with these commands:

- `backtrace`: Shows the current stack. You can use the numbers on the
  left side with the frame command to navigate the stack.
- `up`: Moves the stack frame up. Takes an optional numeric argument
  to move multiple frames.
- `down`: Moves the stack frame down. Takes an optional numeric
  argument to move multiple frames.
- `frame <n>`: Moves to a specific frame. Called without arguments
  displays the current frame.

## Short commands

When you use `binding.pry` instead of `byebug`, the short commands
like `s`, `n`, `f`, and `c` do not work. To reinstall them, add this
to `~/.pryrc`:

```ruby
if defined?(PryByebug)
  Pry.commands.alias_command 's', 'step'
  Pry.commands.alias_command 'n', 'next'
  Pry.commands.alias_command 'f', 'finish'
  Pry.commands.alias_command 'c', 'continue'
end
```

## Repeat last command

You can repeat the last command by just hitting the <kbd>Enter</kbd>
key (for example, with `step` or`next`), if you place the following snippet
in your `~/.pryrc`:

```ruby
Pry::Commands.command /^$/, "repeat last command" do
  _pry_.run_command Pry.history.to_a.last
end
```

`byebug` supports this out-of-the-box.
